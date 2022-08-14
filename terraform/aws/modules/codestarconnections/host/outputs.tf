output "arn" {
  description = "The CodeStar Host ARN."
  value       = aws_codestarconnections_host.this.arn
}

output "id" {
  description = "The CodeStar Host ARN."
  value       = aws_codestarconnections_host.this.id
}

output "status" {
  description = "The CodeStar Host status. Possible values are PENDING, AVAILABLE, VPC_CONFIG_DELETING, VPC_CONFIG_INITIALIZING, and VPC_CONFIG_FAILED_INITIALIZATION."
  value       = aws_codestarconnections_host.this.status
}
