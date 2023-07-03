/*
Copyright 2023 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

###############################################
# VPC
###############################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.cluster_name}-vpc"

  cidr                  = var.vpc_cidr
  secondary_cidr_blocks = var.vpc_secondary_cidr_blocks

  azs             = var.azs
  private_subnets = var.vpc_private_subnet
  public_subnets  = var.vpc_public_subnet

  # intra_subnets are private subnets without the internet access 
  # (https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest#private-versus-intra-subnets)
  intra_subnets = var.vpc_intra_subnet




  # NAT Gateway allows connection to external services (e.g. Internet).
  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true
  one_nat_gateway_per_az = false


  # Tags to allow ELB (Elastic Load Balancing).
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  tags = local.tags
}
