output "sso_instance_arns" {
  value = data.aws_ssoadmin_instances.this.arns
}
