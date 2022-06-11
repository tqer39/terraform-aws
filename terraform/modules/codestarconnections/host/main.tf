resource "aws_codestarconnections_host" "this" {
  name              = lookup(var.aws_codestarconnections_host, "name", null)
  provider_endpoint = lookup(var.aws_codestarconnections_host, "provider_endpoint", null)
  provider_type     = lookup(var.aws_codestarconnections_host, "provider_type", null)
  dynamic "vpc_configuration" {
    for_each = lookup(var.aws_codestarconnections_host, "vpc_configuration", [])
    content {
      security_group_ids = lookup(vpc_configuration.value, "security_group_ids", null)
      subnet_ids         = lookup(vpc_configuration.value, "subnet_ids", null)
      tls_certificate    = lookup(vpc_configuration.value, "tls_certificate", null)
      vpc_id             = lookup(vpc_configuration.value, "vpc_id", null)
    }
  }
}
