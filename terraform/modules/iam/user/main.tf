resource "aws_iam_user" "this" {
  name                 = lookup(var.aws_iam_user, "name", null)
  force_destroy        = lookup(var.aws_iam_user, "force_destroy", false)
  path                 = lookup(var.aws_iam_user, "path", "/")
  permissions_boundary = lookup(var.aws_iam_user, "permissions_boundary", null)
}
