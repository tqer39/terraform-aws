resource "aws_cloudfront_origin_access_identity" "this" {
  comment = lookup(var.aws_cloudfront_origin_access_identity, "comment", null)
}
