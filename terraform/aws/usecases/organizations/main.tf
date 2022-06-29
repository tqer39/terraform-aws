module "organization" {
  source = "../../modules/organizations/organization"
}

module "organizational-units" {
  source = "../../modules/organizations/organizational_unit"

  for_each        = { for i in var.organizational_units : i.name => i }
  name            = each.value.name
  organization_id = module.organization.id

  depends_on = [
    module.organization
  ]
}

module "accounts" {
  source = "../../modules/organizations/account"

  for_each = {
    for account in var.accounts : account.id => {
      name        = account.name
      email       = "${var.organization}+aws-${account.id}@gmail.com"
      parent_type = account.parent_type
    }
  }

  account_name = each.value.name
  email        = each.value.email
  parent_id    = each.value.parent_type == null ? null : module.organizational-units[each.value.parent_type].id

  depends_on = [
    module.organizational-units
  ]
}
