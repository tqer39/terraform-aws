output "arn" {
  description = "The codepipeline ARN."
  value       = aws_codepipeline.this.arn
}

output "id" {
  description = "The codepipeline ID."
  value       = aws_codepipeline.this.id
}
