# backend.hcl
bucket         = "terraform-up-and-running-state"
region         = "ap-south-1"
dynamodb_table = "terraform-up-and-running-locks"
encrypt        = true
key            = "deployment/kube-provisioner.tfstate"
