output "arn" {
  description = "The ARN of the CodeDeploy deployment group."
  value       = aws_codedeploy_deployment_group.this.arn
}

output "compute_platform" {
  description = "The destination platform type for the deployment."
  value       = aws_codedeploy_deployment_group.this.compute_platform
}

output "deployment_group_id" {
  description = "The ID of the CodeDeploy deployment group."
  value       = aws_codedeploy_deployment_group.this.deployment_group_id
}

output "id" {
  description = "Application name and deployment group name."
  value       = aws_codedeploy_deployment_group.this.id
}
