provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }
    time = {
      version = "~> 0.6"
    }
  }

  required_version = "~> 1.0"
}



locals {

  tags = {
    GithubRepo = "kube-provisioner"
    GithubOrg  = "ranajit-jana"
  }
  oidc_provider  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  s3_bucket_name = "vpc-flow-logs-to-s3-${random_pet.this.id}"
}

resource "random_pet" "this" {
  length = 2
}
