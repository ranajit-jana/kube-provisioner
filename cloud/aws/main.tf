

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true


  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    eks_node = {
      instance_types = var.node_group_instance_types
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
    }
  }



  manage_aws_auth_configmap = true


  aws_auth_roles = [
    {
      rolearn  = module.eks_managed_node_group.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]


  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::890504605381:user/terraformrunner"
      username = "terraformrunner"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "890504605381",
  ]

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids


  tags = {
    Environment = "deployment"
    Terraform   = "true"
  }



}

module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "separate-eks-mng"
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

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
}


locals {
  region = "ap-south-1"

  tags = {
    GithubRepo = "kube-provisioner"
    GithubOrg  = "ranajit-jana"
  }
}
