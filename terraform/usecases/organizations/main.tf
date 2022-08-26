resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "aws-artifact-account-sync.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "config.amazonaws.com",
    "controltower.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = { for i in var.organizational_units : i.name => i }

  name      = each.value.name
  parent_id = aws_organizations_organization.this.roots[0].id

  depends_on = [
    aws_organizations_organization.this
  ]
}

resource "aws_organizations_account" "this" {
  for_each = {
    for account in var.accounts : account.id => {
      name              = account.name
      email             = "${var.organization}+aws-${account.id}@gmail.com"
      parent_type       = lookup(account, "parent_type", null)
      close_on_deletion = lookup(account, "close_on_deletion", false)
    }
  }

  name              = each.value.name
  email             = each.value.email
  parent_id         = each.value.parent_type == null ? null : aws_organizations_organizational_unit.this[each.value.parent_type].id
  close_on_deletion = each.value.close_on_deletion

  depends_on = [
    aws_organizations_organizational_unit.this
  ]
}
