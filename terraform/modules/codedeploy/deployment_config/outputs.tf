output "deployment_config_id" {
  description = "The AWS Assigned deployment config id"
  value       = aws_codedeploy_deployment_config.this.deployment_config_id
}

output "id" {
  description = "The deployment group's config name."
  value       = aws_codedeploy_deployment_config.this.id
}
