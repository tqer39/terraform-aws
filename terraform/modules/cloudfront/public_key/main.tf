resource "aws_cloudfront_public_key" "this" {
  comment     = lookup(var.aws_cloudfront_public_key, "comment", null)
  encoded_key = lookup(var.aws_cloudfront_public_key, "encoded_key", null)
  name        = lookup(var.aws_cloudfront_public_key, "name", null)
}
