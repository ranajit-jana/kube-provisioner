# backend.hcl
bucket         = "tf-backend-reva"
region         = "eu-west-1"
dynamodb_table = "reva_tf_lockid"
encrypt        = true
key            = "deployment/kube-provisioner.tfstate"
