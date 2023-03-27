# global
variable "normal_variable" {
  type        = string
  description = "これは通常の variable。sensitiveはデフォルトは false"
  default     = "これは通常の variable"
  sensitive   = false
}

variable "sensitive_variable" {
  type        = string
  description = "これはsensitiveな variable"
  default     = "これはsensitiveな variable"
  sensitive   = true
}
