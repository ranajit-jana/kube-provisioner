
variable "node_group_max_size" {
  type        = number
  description = "eks_managed_node_groups.max_size"
  default     = 1
}


variable "node_group_min_size" {
  type        = number
  description = "eks_managed_node_groups.min_size"
  default     = 1
}


variable "node_group_desired_size" {
  type        = number
  description = "eks_managed_node_groups.desired_size"
  default     = 1
}

variable "node_group_instance_types" {

  type        = list(string)
  description = "ec2 instance type"

}

variable "vpc_id" {
  type = string
}


variable "subnet_ids" {
  type = list(string)
}


variable "cluster_version" {
  type = string
}


variable "cluster_name" {
  type = string
}


variable "cluster_endpoint_public_access_cidrs" {

  type        = list(string)
  description = "cluster_endpoint_public_access_cidrs"

}

variable "cluster_endpoint_public_access" {
}
variable "cluster_endpoint_private_access" {
}
variable "create_kms_key" {
}
variable "kms_key_enable_default_policy" {
}
variable "access_role" {
}

variable "account_number" {
}
