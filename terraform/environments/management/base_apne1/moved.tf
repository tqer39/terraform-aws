moved {
  from = module.deploy-role.module.iam-role.aws_iam_role.this
  to   = module.deploy-role.aws_iam_role.this
}

moved {
  from = module.deploy-role.module.iam-policy.aws_iam_policy.this
  to   = module.deploy-role.aws_iam_policy.this
}
