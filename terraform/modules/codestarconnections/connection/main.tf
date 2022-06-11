resource "aws_codestarconnections_connection" "this" {
  name          = lookup(var.aws_codestarconnections_connection, "name", null)
  provider_type = lookup(var.aws_codestarconnections_connection, "provider_type", null)
  host_arn      = lookup(var.aws_codestarconnections_connection, "host_arn", null)
}
