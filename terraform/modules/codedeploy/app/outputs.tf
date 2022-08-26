output "arn" {
  description = "The ARN of the CodeDeploy application."
  value       = aws_codedeploy_app.this.arn
}

output "application_id" {
  description = "The application ID."
  value       = aws_codedeploy_app.this.application_id
}

output "id" {
  description = "Amazon's assigned ID for the application."
  value       = aws_codedeploy_app.this.id
}

output "name" {
  description = "The application's name."
  value       = aws_codedeploy_app.this.name
}

output "github_account_name" {
  description = "The name for a connection to a GitHub account."
  value       = aws_codedeploy_app.this.github_account_name
}

output "linked_to_github" {
  description = "Whether the user has authenticated with GitHub for the specified application."
  value       = aws_codedeploy_app.this.linked_to_github
}
