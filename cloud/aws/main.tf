locals {
  root_account_arn = "arn:aws:iam::890504605381:root"
  tags             = { "name" : "project" }
}


provider "aws" {
  region = var.cluster_region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.10.0"

  # General cluster properties.
  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Manage aws-auth ConfigMap.
  manage_aws_auth_configmap = false

  create_kms_key = true
  # Allow access to the KMS key used for secrets encryption to the root account.
  kms_key_administrators = [
    local.root_account_arn
  ]


  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = " 1025 to 65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = " open all"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description = " open all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ipvs = {
      description = " open all IPVS port"
      protocol    = "TCP"
      from_port   = 32000
      to_port     = 34000
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_cluster_all = {
      description                = " open all control plane port"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "ingress"
      source_node_security_group = true
    }

  }

  # We use IPv4 for the best compatibility with the existing setup.
  # Additionally, Ubuntu EKS optimized AMI doesn't support IPv6 well.
  cluster_ip_family = "ipv4"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m6i.large", "m5.large"]

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
    create_launch_template     = true
    launch_template_name       = ""
    create_security_group      = false
  }

  kms_key_deletion_window_in_days = 7
}

resource "aws_eks_addon" "coredns" {
  addon_name        = "coredns"
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [module.eks_managed_node_group]
}

resource "aws_eks_addon" "vpc-cni" {
  addon_name        = "vpc-cni"
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [module.eks_managed_node_group]
}

resource "aws_eks_addon" "kubeproxy" {
  addon_name        = "kube-proxy"
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [module.eks_managed_node_group]
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    "mapAccounts" = yamlencode([])
    "mapRoles" = yamlencode([
      {
        rolearn  = aws_iam_role.nodegroup_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
      {
        rolearn  = "arn:aws:iam::890504605381:role/terraformuser"
        username = "terraformuser"
        groups = [
          "system:masters"
        ]
      },
    ])
    "mapUsers" = yamlencode([
      {
        userarn  = "arn:aws:iam::890504605381:user/kubeuser"
        username = "kubeuser"
        groups = [
          "system:masters"
        ]
      },
    ])
  }
  lifecycle {
    ignore_changes = [
      data,
      metadata
    ]
  }
  depends_on = [module.eks]
}

resource "aws_iam_role" "nodegroup_role" {
  name               = "eks-nodegroup-nodegrouprole"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service":[
          "ec2.amazonaws.com"
          ]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

# resource "aws_iam_role_policy_attachment" "ng_workers" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.nodegroup_role.name
# }

# resource "aws_iam_role_policy_attachment" "ng_ecr" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.nodegroup_role.name
# }

# resource "aws_iam_role_policy_attachment" "ng_cni" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.nodegroup_role.name
# }



resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]) : k => v }

  policy_arn = each.value
  role       = aws_iam_role.nodegroup_role.name
}


# module "eks_managed_node_group" {
#   source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
#   version = "19.5.1"
#   create  = true

#   name            = "separate-eks-mng"
#   cluster_name    = var.cluster_name
#   cluster_version = var.cluster_version
#   subnet_ids      = module.vpc.private_subnets

#   // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
#   // Without it, the security groups of the nodes are empty and thus won't join the cluster.
#   cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
#   vpc_security_group_ids            = [module.eks.node_security_group_id]

#   ami_type                   = "AL2_x86_64"
#   instance_types             = ["m6i.large", "m5.large"]
#   create_iam_role            = false
#   iam_role_arn               = aws_iam_role.nodegroup_role.arn
#   iam_role_attach_cni_policy = false
#   cluster_ip_family          = "ipv4"
#   min_size                   = 1
#   max_size                   = 2
#   desired_size               = 1

#   depends_on = [kubernetes_config_map.aws_auth]
# }
module "eks_managed_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "19.5.1"

  name            = "separate-eks-mng"
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

  subnet_ids = module.vpc.private_subnets
  vpc_security_group_ids = [
    module.eks.cluster_primary_security_group_id,
    module.eks.cluster_security_group_id,
  ]

  create_iam_role = false
  iam_role_arn    = aws_iam_role.nodegroup_role.arn

  min_size     = 1
  max_size     = 3
  desired_size = 1

  tags = local.tags
}