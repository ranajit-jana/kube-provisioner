

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "race-capstone"
  cluster_version = "1.25"

  cluster_endpoint_public_access = false


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
    default = {
      instance_types = ["t3a.medium"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }


  vpc_id     = "vpc-0aa863f04f42d7a17"
  subnet_ids = ["subnet-06d71bcd8eab5d7cc", "subnet-0016baaa1ad983d1d", "subnet-07c713ac6f9a1f780"]


  tags = {
    Environment = "deployment"
    Terraform   = "true"
  }



}
