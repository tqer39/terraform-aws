output "arn" {
  description = "The CodePipeline webhook's ARN."
  value       = aws_codepipeline_webhook.this.arn
}

output "id" {
  description = "The CodePipeline webhook's ARN."
  value       = aws_codepipeline_webhook.this.id
}

output "url" {
  description = "The CodePipeline webhook's URL. POST events to this endpoint to trigger the target."
  value       = aws_codepipeline_webhook.this.url
}
