resource "aws_codestarnotifications_notification_rule" "this" {
  detail_type    = lookup(var.aws_codestarnotifications_notification_rule, "detail_type", null)
  event_type_ids = lookup(var.aws_codestarnotifications_notification_rule, "event_type_ids", null)
  name           = lookup(var.aws_codestarnotifications_notification_rule, "name", null)
  resource       = lookup(var.aws_codestarnotifications_notification_rule, "resource", null)
  status         = lookup(var.aws_codestarnotifications_notification_rule, "status", null)
  dynamic "target" {
    for_each = lookup(var.aws_codestarnotifications_notification_rule, "target", [])
    content {
      address = lookup(target.value, "address", null)
      type    = lookup(target.value, "type", null)
    }
  }
}
