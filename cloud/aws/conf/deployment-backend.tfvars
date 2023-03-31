# backend.hcl
bucket         = "deployment-env-state"
region         = "ap-south-1"
dynamodb_table = "deployment-state-race-reva-locks"
encrypt        = true
key            = "deployment/kube-provisioner.tfstate"
