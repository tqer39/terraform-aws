resource "aws_acm_certificate" "this" {
  domain_name = lookup(var.aws_acm_certificate, "domain_name", null)
  dynamic "options" {
    for_each = lookup(var.aws_acm_certificate, "options", [])
    content {
      certificate_transparency_logging_preference = lookup(options.value, "certificate_transparency_logging_preference", null)
    }
  }
  subject_alternative_names = lookup(var.aws_acm_certificate, "subject_alternative_names", null)
  validation_method         = lookup(var.aws_acm_certificate, "validation_method", null)
  lifecycle {
    create_before_destroy = true
  }
}
