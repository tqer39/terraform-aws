module "deploy_role" {
  source = "../../../usecases/deploy_role/terraform_github"

  aws_account_id = local.aws_account_id
  aws_env_name   = local.aws_env_name
  organization   = local.organization
  repository     = "terraform-github"
}