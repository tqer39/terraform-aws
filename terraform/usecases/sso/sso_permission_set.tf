resource "aws_ssoadmin_permission_set" "main" {
  for_each = toset([
    "AdministratorAccess",
    "ReadOnlyAccess"
  ])

  name             = each.value
  description      = "Managed by Terraform"
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  session_duration = "PT12H"
}
