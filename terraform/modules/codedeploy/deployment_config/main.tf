resource "aws_codedeploy_deployment_config" "this" {
  deployment_config_name = lookup(var.aws_codecommit_approval_rule_template, "content", null)
  dynamic "minimum_healthy_hosts" {
    for_each = lookup(var.aws_codedeploy_deployment_config, "minimum_healthy_hosts", [])
    content {
      type  = lookup(minimum_healthy_hosts.value, "type", null)
      value = lookup(minimum_healthy_hosts.value, "value", null)
    }
  }
  dynamic "traffic_routing_config" {
    for_each = lookup(var.aws_codedeploy_deployment_config, "traffic_routing_config", [])
    content {
      type = lookup(traffic_routing_config.value, "type", null)
      dynamic "time_based_canary" {
        for_each = lookup(traffic_routing_config.value, "time_based_canary", [])
        content {
          interval   = lookup(time_based_canary.value, "interval", null)
          percentage = lookup(time_based_canary.value, "percentage", null)
        }
      }
      dynamic "time_based_linear" {
        for_each = lookup(traffic_routing_config.value, "time_based_linear", [])
        content {
          interval   = lookup(time_based_linear.value, "interval", null)
          percentage = lookup(time_based_linear.value, "percentage", null)
        }
      }
    }
  }
}
