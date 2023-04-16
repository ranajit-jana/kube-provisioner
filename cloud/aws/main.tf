

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
