module "oidc_github_actions_id_provider" {
  source = "../../../modules/id_provider"
}

# import {
#   id = "module.oidc_github_actions_id_provider.aws_iam_openid_connect_provider.this"
#   to = module.oidc_github_actions_id_provider.aws_iam_openid_connect_provider.this
# }
