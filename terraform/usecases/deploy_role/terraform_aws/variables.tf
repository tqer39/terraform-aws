variable "aws_account_id" {
  type        = string
  description = "(Required) AWS account ID"
}

variable "aws_env_name" {
  type        = string
  description = "(Required) AWS Environment name"
}

variable "organization" {
  type        = string
  description = "(Required) GitHub organization name"
}

variable "repository" {
  type        = string
  description = "(Required) GitHub repository name"
}

variable "sso_role_arns" {
  type        = list(string)
  description = "(Required) List of SSO role ARNs"
}
