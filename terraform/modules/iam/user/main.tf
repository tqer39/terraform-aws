resource "aws_iam_user" "this" {
  name                 = lookup(var.aws_iam_role, "name", null)
  force_destroy        = lookup(var.aws_iam_role, "force_destroy", false)
  path                 = lookup(var.aws_iam_role, "path", "/")
  permissions_boundary = lookup(var.aws_iam_role, "permissions_boundary", null)
}
