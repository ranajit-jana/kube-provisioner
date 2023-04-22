node_group_max_size       = 4
node_group_min_size       = 1
node_group_desired_size   = 2
node_group_instance_types = ["t3a.medium"]

account_number = 890504605381

vpc_id     = "vpc-0aa863f04f42d7a17"
subnet_ids = ["subnet-06d71bcd8eab5d7cc", "subnet-0016baaa1ad983d1d", "subnet-07c713ac6f9a1f780"]

cluster_name                         = "race-capstone"
cluster_version                      = "1.25"
cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

create_kms_key                = true
kms_key_enable_default_policy = true
legacy_nodegroup              = false

access_role = "arn:aws:iam::890504605381:role/terraformuser"

