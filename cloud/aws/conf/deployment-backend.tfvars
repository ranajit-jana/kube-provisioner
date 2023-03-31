# backend.hcl
bucket         = "deployment-env-state"
region         = "ap-south-1"
dynamodb_table = "deployment-env-state-lock"
encrypt        = true
key            = "deployment/kube-provisioner.tfstate"
