resource "aws_codecommit_approval_rule_template" "this" {
  content     = lookup(var.aws_codecommit_approval_rule_template, "content", null)
  name        = lookup(var.aws_codecommit_approval_rule_template, "name", null)
  description = lookup(var.aws_codecommit_approval_rule_template, "description", null)
}
