locals {
  users = [
    { name = "hoge" },
    { name = "fuga" },
    { name = "moga" },
    { name = "hhh" },
  ]
}

module "create-users" {
  source = "../../../usecases/create_users"

  users = local.users
}
