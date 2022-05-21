locals {
  organizational_units = [
    { name = "Sandbox" },
    { name = "Security" },
    { name = "WorkLoad" },
  ]

  accounts = [
    { name = "Audit", id = "audit", root = false, parent_type = "Security" },
    { name = "Log Archive", id = "log", root = false, parent_type = "WorkLoad" },
    { name = "Management", id = "management", root = true, parent_type = null },
    { name = "Sandbox", id = "sandbox", root = false, parent_type = "Sandbox" },
    { name = "Portfolio - dev", id = "portfolio-dev", root = false, parent_type = "Security" },
  ]
}

module "organizations" {
  source = "../../../usecases/organizations"

  accounts             = local.accounts
  organization         = local.organization
  organizational_units = local.organizational_units
}
