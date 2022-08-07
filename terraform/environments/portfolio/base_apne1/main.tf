module "tfstate-s3-bucket" {
  source = "../../../usecases/base/terraform_tfstate_backend"

  bucket_name = local.tfstate_bucket_name.apne1
}

module "deploy-role" {
  source = "../../../usecases/base/deploy_role_private_lab"

  aws_account_id = local.aws_account_id
  env_name       = local.env_name
  organization   = local.organization
  repository     = local.repository
}

module "oidc-github-actions-id-provider" {
  source = "../../../usecases/base/id_provider"
}
