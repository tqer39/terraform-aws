variable "users" {
  type = list(object({
    name = string
  }))
}
