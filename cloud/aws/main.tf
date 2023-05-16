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
# INITIALIZATION
###############################################

provider "aws" {
  region = var.cluster_region

  # We have a chicken-egg problem here. This role is not going to exist
  # when creating the cluster for the first time. In that case, this must
  # be commented, than uncommented afterwards.
  # assume_role {
  #   role_arn     = "arn:aws:iam::468814281478:role/Cluster-Admin"
  #   session_name = "build-cluster-terraform"
  # }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  # This requires the awscli to be installed locally where Terraform is executed.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", aws_iam_role.iam_cluster_admin.arn]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    # This requires the awscli to be installed locally where Terraform is executed.
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--role-arn", aws_iam_role.iam_cluster_admin.arn]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  root_account_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

  tags = {
    Cluster = var.cluster_name
  }
  auto_scaling_tags = {
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"             = true
  }
  node_group_tags = merge(local.tags, local.auto_scaling_tags)
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
}
