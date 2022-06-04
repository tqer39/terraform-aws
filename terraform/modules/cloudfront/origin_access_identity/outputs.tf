output "cloudfront_access_identity_path" {
  value = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
}

output "id" {
  value = aws_cloudfront_origin_access_identity.this.id
}
