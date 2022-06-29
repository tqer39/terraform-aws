
module "iam_users" {
  source = "../../../modules/iam_user/test_user"

  for_each  = { for i in local.users : i.name => i }
  user_name = each.value.name
}
