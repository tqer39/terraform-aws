locals {
  users = [
    { name = "hoge" },
    { name = "fuga" },
    { name = "moga" },
  ]
}

module "create-users" {
  source = "../../../modules/create_users"

  users = local.users
}
