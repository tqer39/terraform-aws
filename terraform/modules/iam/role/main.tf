resource "aws_iam_role" "this" {
  name               = lookup(var.aws_iam_role, "name", "")
  assume_role_policy = lookup(var.aws_iam_role, "assume_role_policy", "")
  dynamic "inline_policy" {
    for_each = lookup(var.aws_iam_role, "inline_policy", [])
    content {
      name   = lookup(inline_policy.value, "name", null)
      policy = lookup(inline_policy.value, "policy", null)
    }
  }
  managed_policy_arns = lookup(var.aws_iam_role, "managed_policy_arns", [])
}
