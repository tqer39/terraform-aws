output "sso_instance_arns" {
  description = "Set of Amazon Resource Names (ARNs) of the SSO Instances."
  value       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

output "sso_instance_id" {
  description = "AWS Region."
  value       = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

output "sso_instance_identity_store_ids" {
  description = "Set of identifiers of the identity stores connected to the SSO Instances."
  value       = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)
}
