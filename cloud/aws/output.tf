output "cluster_addons" {
  value = module.eks.cluster_addons
}

output "self_managed_node_groups" {
  value = module.eks.self_managed_node_groups

}

output "cluster_autoscaler_irsa_role_arn" {
  value = module.cluster_autoscaler_irsa_role.iam_role_arn

}

