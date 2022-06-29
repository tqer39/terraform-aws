resource "aws_codecommit_approval_rule_template_association" "this" {
  approval_rule_template_name = lookup(var.aws_codecommit_approval_rule_template_association, "approval_rule_template_name", null)
  repository_name             = lookup(var.aws_codecommit_approval_rule_template_association, "repository_name", null)
}
