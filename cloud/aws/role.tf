module "irsa-kube-bench" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.27.0"

  create_role                    = true
  role_name                      = "kube_bench_security_hub_role-${module.eks.cluster_name}"
  provider_url                   = module.eks.oidc_provider
  role_policy_arns               = [aws_iam_policy.kube_bench_security_hub.arn]
  oidc_subjects_with_wildcards   = ["system:serviceaccount:kube-bench:*"]
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
}




resource "aws_iam_policy" "kube_bench_security_hub" {
  name        = "kube_bench_security_hub_${module.eks.cluster_name}"
  description = "Kube-bench integration to AWS Security Hub"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "securityhub:BatchImportFindings",
        "Resource" : "arn:aws:securityhub:us-east-1::product/aqua-security/kube-bench"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kube_bench_security_hub" {
  role       = aws_iam_role.nodegroup_role.name
  policy_arn = aws_iam_policy.kube_bench_security_hub.arn

  depends_on = [module.eks_managed_node_group]
}
