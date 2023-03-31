provider "aws" {
  region  = "ap-south-1"
  version = "~> 4.61"
}

terraform {
  backend "s3" {
  }
}
