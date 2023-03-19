moved {
  from = module.deploy-role.aws_iam_policy.this
  to   = module.deploy_role.aws_iam_policy.this
}

moved {
  from = module.deploy-role.aws_iam_role.this
  to   = module.deploy_role.aws_iam_role.this
}

moved {
  from = module.tfstate-s3-bucket.module.s3-bucket.aws_s3_bucket.this
  to   = module.tfstate_s3_bucket.module.s3_bucket.aws_s3_bucket.this
}

moved {
  from = module.tfstate-s3-bucket.module.s3-bucket.aws_s3_bucket_versioning.this[0]
  to   = module.tfstate_s3_bucket.module.s3_bucket.aws_s3_bucket_versioning.this[0]
}

moved {
  from = module.tfstate-s3-bucket.module.s3-bucket.aws_s3_bucket_public_access_block.this
  to   = module.tfstate_s3_bucket.module.s3_bucket.aws_s3_bucket_public_access_block.this
}

moved {
  from = module.tfstate-s3-bucket.module.s3-bucket.aws_s3_bucket_public_access_block.this
  to   = module.tfstate_s3_bucket.module.s3_bucket.aws_s3_bucket_public_access_block.this
}

moved {
  from = module.oidc-github-actions-id-provider.aws_iam_openid_connect_provider.this
  to   = module.oidc_github_actions_id_provider.aws_iam_openid_connect_provider.this
}
