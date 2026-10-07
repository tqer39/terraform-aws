locals {
  organizational_units = [
    { name = "Sandbox" },
    { name = "Security" },
    { name = "WorkLoad" },
  ]

  accounts = [
    {
      name        = "Audit",
      id          = "audit",
      parent_type = "Security"
    },
    {
      name        = "Log Archive",
      id          = "log",
      parent_type = "WorkLoad"
    },
    {
      name = "Management",
      id   = "management",
      root = true,
    },
    {
      name        = "Sandbox",
      id          = "sandbox",
      parent_type = "Sandbox"
    },
    {
      name        = "Portfolio",
      id          = "portfolio",
      parent_type = "WorkLoad"
    }
  ]
}

module "organizations" {
  source = "../../../usecases/organizations"

  accounts             = local.accounts
  owner                = local.owner
  organizational_units = local.organizational_units
}
