resource "aws_iam_user" "this" {
  for_each = { for user in var.users : user.name => user }

  name = each.value.name
}
