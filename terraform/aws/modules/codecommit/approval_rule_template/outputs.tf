output "approval_rule_template_id" {
  description = "The ID of the approval rule template"
  value       = aws_codecommit_approval_rule_template.this.approval_rule_template_id
}

output "creation_date" {
  description = "The date the approval rule template was created, in RFC3339 format."
  value       = aws_codecommit_approval_rule_template.this.creation_date
}

output "last_modified_date" {
  description = "The date the approval rule template was most recently changed, in RFC3339 format."
  value       = aws_codecommit_approval_rule_template.this.last_modified_date
}

output "last_modified_user" {
  description = "The Amazon Resource Name (ARN) of the user who made the most recent changes to the approval rule template."
  value       = aws_codecommit_approval_rule_template.this.last_modified_user
}

output "rule_content_sha256" {
  description = "The SHA-256 hash signature for the content of the approval rule template."
  value       = aws_codecommit_approval_rule_template.this.rule_content_sha256
}
