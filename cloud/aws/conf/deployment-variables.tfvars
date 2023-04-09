node_group_max_size       = 4
node_group_min_size       = 1
node_group_desired_size   = 2
node_group_instance_types = ["t3a.medium"]


vpc_id = "vpc-0aa863f04f42d7a17"

cluster_name    = "race-capstone"
cluster_version = "1.25"

subnet_ids = ["subnet-06d71bcd8eab5d7cc", "subnet-0016baaa1ad983d1d", "subnet-07c713ac6f9a1f780"]
