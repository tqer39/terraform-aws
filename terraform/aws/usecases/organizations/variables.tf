variable "accounts" {
  type = list(object({
    name        = string
    id          = string
    root        = bool
    parent_type = string
  }))
}

variable "organizational_units" {
  type = list(object({
    name = string
  }))
}

variable "organization" {
  type = string
}
