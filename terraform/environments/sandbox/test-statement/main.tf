# variable "names" {
#   type    = tuple([string, string, string])
#   default = ["hoge", "fuga", "moga"]
# }

locals {
  users = [
    { name = "hoge" },
    { name = "fuga" },
    { name = "moga" },
  ]
  # users = tuple([
  #   object({ name = "hoge" }),
  #   object({ name = "fuga" }),
  #   object({ name = "moga" }),
  # ])
  # users = {
  #   hoge = {
  #     name = "hoge"
  #   },
  #   fuga = {
  #     name = "fuga"
  #   },
  #   moga = {
  #     name = "moga"
  #   },
  # }
}

module "iam_users" {
  source = "../../../modules/iam_user/test_user"

  # for_each = var.user_name
  for_each  = { for i in local.users : i.name => i }
  # for_each  = local.users.name
  user_name = each.value.name

  # user_name = each.value.user_name
  # user_names = var.user_name
  # user_names = var.user_name
}
