
variable "node_group_max_size" {
  description = "eks_managed_node_groups.max_size"
  default     = 1
}


variable "node_group_min_size" {
  description = "eks_managed_node_groups.min_size"
  default     = 1
}


variable "node_group_desired_size" {
  description = "eks_managed_node_groups.desired_size"
  default     = 1
}

variable "node_group_instance_types" {
  type    = list(string)
  default = ["t3a.medium"]
}
