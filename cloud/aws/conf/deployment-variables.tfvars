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

cluster_name    = "my-eks"
cluster_region  = "us-east-1"
cluster_version = "1.25"

vpc_cidr                  = "10.0.0.0/16"
vpc_secondary_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16"]
vpc_public_subnet         = ["10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"]
vpc_private_subnet        = ["10.1.0.0/18", "10.1.64.0/18", "10.1.128.0/18"]
vpc_intra_subnet          = ["10.2.0.0/18", "10.2.64.0/18", "10.2.128.0/18"]

# Ubuntu EKS optimized AMI: https://cloud-images.ubuntu.com/aws-eks/
node_ami            = "ami-0ca4a88bd4c573f41"
node_instance_types = ["t3.medium"]
node_volume_size    = 30

# TODO(xmudrii): Increase this later.
node_min_size                   = 2
node_max_size                   = 2
node_desired_size               = 2
node_max_unavailable_percentage = 100 # To ease testing

cluster_autoscaler_version = "v1.25.0"
