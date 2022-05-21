resource "aws_organizations_account" "this" {
  name      = var.account_name
  email     = var.email
  parent_id = var.parent_id
}
