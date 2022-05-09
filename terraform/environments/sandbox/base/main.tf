module "deploy-role" {
  source = "../../../usecases/oidc_permission"

  aws_account_id = local.aws_account_id
  env_name       = local.env_name
  organization   = local.organization
  repository     = local.repository
}

module "oidc-github-actions" {
  source = "../../../usecases/base/id_provider"
}

module "terraform-backend" {
  source = "../../../usecases/base/s3"

  aws_account_id = local.aws_account_id
  aws_region     = local.aws_region
  organization   = local.organization
}
