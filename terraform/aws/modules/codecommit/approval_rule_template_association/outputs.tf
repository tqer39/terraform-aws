output "id" {
  description = "The name of the approval rule template and name of the repository, separated by a comma (,)."
  value       = aws_codecommit_approval_rule_template_association.this.id
}
