resource "aws_guardduty_detector" "this" {
  enable                       = lookup(var.aws_guardduty_detector, "enable", null)
  finding_publishing_frequency = lookup(var.aws_guardduty_detector, "finding_publishing_frequency", null)
  dynamic "datasources" {
    for_each = lookup(var.aws_guardduty_detector, "datasources", [])
    dynamic "s3_logs" {
      for_each = lookup(datasources.value, "s3_logs", [])
      content {
        enable = lookup(s3_logs.value, "enable", null)
      }
    }
    dynamic "kubernetes" {
      for_each = lookup(var.aws_guardduty_detector, "kubernetes", [])
      content {
        dynamic "audit_logs" {
          for_each = lookup(kubernetes.value, "audit_logs", [])
          content {
            enable = lookup(audit_logs.value, "enable", null)
          }
        }
      }
    }
  }
}
