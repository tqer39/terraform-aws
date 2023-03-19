data "aws_organizations_organization" "this" {}

resource "aws_ssoadmin_account_assignment" "admin" {
  for_each = toset(data.aws_organizations_organization.this.accounts[*].id)

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.main["AdministratorAccess"].arn
  principal_id   = data.aws_identitystore_group.admin.group_id
  principal_type = "GROUP"
  target_id   = each.value
  target_type = "AWS_ACCOUNT"
}
