module "deploy_role" {
  source = "../../../usecases/deploy_role/time_capsule"

  aws_account_id = local.aws_account_id
  aws_env_name   = local.aws_env_name
  organization   = local.organization
  repository     = "time-capsule"
}
