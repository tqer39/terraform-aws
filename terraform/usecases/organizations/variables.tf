variable "accounts" {
  type    = any
  default = null
}

variable "organizational_units" {
  type = list(object({
    name = string
  }))
}

variable "organization" {
  type = string
}
