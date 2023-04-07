

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "race-capstone"
  cluster_version = "1.25"

  cluster_endpoint_public_access = false


  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = "vpc-0aa863f04f42d7a17"
  subnet_ids = ["subnet-06d71bcd8eab5d7cc", "subnet-0016baaa1ad983d1d", "subnet-07c713ac6f9a1f780"]



  # Self Managed Node Group(s)
  self_managed_node_group_defaults = {
    instance_type                          = "t3a.medium"
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "t3a.medium"
            weighted_capacity = "1"
          },
          {
            instance_type     = "t3a.large"
            weighted_capacity = "2"
          },
        ]
      }
    }
  }




  tags = {
    Environment = "deployment"
    Terraform   = "true"
  }



}
