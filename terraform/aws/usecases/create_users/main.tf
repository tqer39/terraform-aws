module "iam-user" {
  source = "../../modules/iam/user"

  for_each = { for user in var.users : user.name => user }
  aws_iam_user = {
    name = each.value.name
  }
}
