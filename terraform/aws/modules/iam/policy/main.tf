resource "aws_iam_policy" "this" {
  description = lookup(var.aws_iam_policy, "description", null)
  name        = lookup(var.aws_iam_policy, "name", null)
  path        = lookup(var.aws_iam_policy, "path", "/")
  policy      = lookup(var.aws_iam_policy, "policy", null)
}
