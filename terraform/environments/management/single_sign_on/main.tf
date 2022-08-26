# # admins
# resource "aws_ssoadmin_account_assignment" "audit_admins" {
#   instance_arn       = aws_ssoadmin_permission_set.admins.instance_arn
#   permission_set_arn = aws_ssoadmin_permission_set.admins.arn
#   principal_id       = data.aws_identitystore_group.admins.group_id
#   principal_type     = "GROUP"
#   target_id          = local.aws_account_ids["audit"]
#   target_type        = "AWS_ACCOUNT"
# }

module "sso" {
  source = "../../../usecases/sso"
}
