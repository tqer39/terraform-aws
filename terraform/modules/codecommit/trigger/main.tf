resource "aws_codecommit_trigger" "this" {
  repository_name = lookup(var.aws_codecommit_trigger, "repository_name", null)
  dynamic "trigger" {
    for_each = lookup(var.aws_codecommit_trigger, "trigger", [])
    content {
      name            = lookup(trigger.value, "name", null)
      events          = lookup(trigger.value, "events", null)
      destination_arn = lookup(trigger.value, "destination_arn", null)
    }
  }
}
