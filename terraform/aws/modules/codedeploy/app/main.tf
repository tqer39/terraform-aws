resource "aws_codedeploy_app" "this" {
  compute_platform = lookup(var.aws_codedeploy_app, "compute_platform", "Server")
  description      = lookup(var.aws_codedeploy_app, "description", null)
  name             = lookup(var.aws_codedeploy_app, "name", null)
}
