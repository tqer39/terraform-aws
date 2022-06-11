variable "aws_codedeploy_app" {
  description = "Provides a CodeDeploy application to be used as a basis for deployments aws_codedeploy_app, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app"
  type        = any
  default     = null
}
