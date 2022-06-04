resource "aws_cloudfront_key_group" "this" {
  comment = lookup(var.aws_cloudfront_key_group, "comment", null)
  items   = lookup(var.aws_cloudfront_key_group, "items", null)
  name    = lookup(var.aws_cloudfront_key_group, "name", null)
}
