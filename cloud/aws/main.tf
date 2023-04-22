
locals {
  region = "ap-south-1"

  tags = {
    GithubRepo = "kube-provisioner"
    GithubOrg  = "ranajit-jana"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version


  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  create_kms_key                       = var.create_kms_key
  kms_key_enable_default_policy        = var.kms_key_enable_default_policy


  kms_key_administratorys = var.access_role

  create_cni_ipv6_iam_policy = false

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_all = {
      description                = "Acess from control plane"
      protocol                   = "-1"
      from_port                  = 0
      to_port                    = 0
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  #managed from outside
  manage_aws_auth_configmap = false




  tags = {
    Environment = "deployment"
    Terraform   = "true"
  }



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
        rolearn  = module.eks_managed_node_group.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
      {
        rolearn  = "arn:aws:iam::890504605381:role/terraformuser"
        username = "terraformrunner"
        groups   = ["system:masters"]
      }

    ])
    "mapUsers" = yamlencode([])
  }

  lifecycle {
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }

  depends_on = [
    module.eks, module.eks_managed_node_group
  ]
}

resource "aws_eks_addon" "coredns" {
  addon_name        = "coredns"
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  depends_on = [
    module.eks_managed_node_group
  ]
}

resource "aws_eks_addon" "kubeproxy" {
  addon_name        = "kube-proxy"
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  depends_on = [
    module.eks_managed_node_group
  ]

}

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = each.key
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

  min_size     = var.node_group_min_size
  max_size     = var.node_group_max_size
  desired_size = var.node_group_desired_size



  instance_types = ["t3.large"]
  capacity_type  = "SPOT"


  subnet_ids                        = var.subnet_ids
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids = [
    module.eks.cluster_security_group_id,
  ]

  ami_type = "BOTTLEROCKET_x86_64"
  platform = "bottlerocket"

  # this will get added to what AWS provides
  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
    [settings.kubernetes.node-labels]
    "label1" = "race"
    "label2" = "capstone"
  EOT

  tags = merge(local.tags, { Separate = "eks-managed-node-group" })

  depends_on = [
    module.eks
  ]
}



resource "aws_iam_role_policy_attachment" "ng_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = module.eks_managed_node_group.iam_role_arn
}


resource "aws_iam_role_policy_attachment" "ng_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = module.eks_managed_node_group.iam_role_arn
}


resource "aws_iam_role_policy_attachment" "ng_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = module.eks_managed_node_group.iam_role_arn
}

resource "aws_iam_role" "ng_role" {
  name               = "kube-${var.cluster_name}-NodeGroupRole"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17"
    "Statement": [
      {
       "Effect": "Allow"
       "Principal": {
        "Service":[
          "ec2.amazonaws.com
        ]
       },
       "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

