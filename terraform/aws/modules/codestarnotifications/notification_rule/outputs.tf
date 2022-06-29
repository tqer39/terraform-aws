output "arn" {
  description = "The codestar notification rule ARN."
  value       = aws_codestarnotifications_notification_rule.this.arn
}

output "id" {
  description = "The codestar notification rule ARN."
  value       = aws_codestarnotifications_notification_rule.this.id
}
