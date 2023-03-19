variable "accounts" {
  type        = any
  description = "(Require) List of accounts to create."
  default     = null
}

variable "organizational_units" {
  type = list(object({
    name = string
  }))
  description = "(Require) List of organizational units to create."
}

variable "owner" {
  type        = string
  description = "(Require) Owner of the accounts."
}
