resource "aws_ssoadmin_permission_set" "main" {
  for_each = toset([
    "AdministratorAccess",
    "ReadOnlyAccess"
  ])

  name         = each.value
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}
