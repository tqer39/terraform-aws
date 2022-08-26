resource "aws_codedeploy_deployment_group" "this" {
  app_name               = lookup(var.aws_codedeploy_deployment_group, "app_name", null)
  autoscaling_groups     = lookup(var.aws_codedeploy_deployment_group, "autoscaling_groups", null)
  deployment_config_name = lookup(var.aws_codedeploy_deployment_group, "deployment_config_name", null)
  deployment_group_name  = lookup(var.aws_codedeploy_deployment_group, "deployment_group_name", null)
  service_role_arn       = lookup(var.aws_codedeploy_deployment_group, "service_role_arn", null)
  dynamic "alarm_configuration" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "alarm_configuration", [])
    content {
      alarms  = lookup(alarm_configuration.value, "alarms", null)
      enabled = lookup(alarm_configuration.value, "enabled", null)
    }
  }
  dynamic "auto_rollback_configuration" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "auto_rollback_configuration", [])
    content {
      enabled = lookup(auto_rollback_configuration.value, "enabled", null)
      events  = lookup(auto_rollback_configuration.value, "events", null)
    }
  }
  dynamic "blue_green_deployment_config" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "blue_green_deployment_config", [])
    content {
      dynamic "deployment_ready_option" {
        for_each = lookup(blue_green_deployment_config.value, "deployment_ready_option", [])
        content {
          action_on_timeout = lookup(deployment_ready_option.value, "action_on_timeout", null)
        }
      }
      dynamic "green_fleet_provisioning_option" {
        for_each = lookup(blue_green_deployment_config.value, "green_fleet_provisioning_option", [])
        content {
          action = lookup(green_fleet_provisioning_option.value, "action", null)
        }
      }
      dynamic "terminate_blue_instances_on_deployment_success" {
        for_each = lookup(blue_green_deployment_config.value, "terminate_blue_instances_on_deployment_success", [])
        content {
          action                           = lookup(terminate_blue_instances_on_deployment_success.value, "action", null)
          termination_wait_time_in_minutes = lookup(terminate_blue_instances_on_deployment_success.value, "termination_wait_time_in_minutes", null)
        }
      }
    }
  }
  dynamic "deployment_style" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "deployment_style", [])
    content {
      deployment_option = lookup(deployment_style.value, "deployment_option", null)
      deployment_type   = lookup(deployment_style.value, "deployment_type", null)
    }
  }
  dynamic "ec2_tag_set" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "ec2_tag_set", [])
    content {
      dynamic "ec2_tag_filter" {
        for_each = lookup(ec2_tag_set.value, "ec2_tag_filter", [])
        content {
          key   = lookup(ec2_tag_filter.value, "key", null)
          type  = lookup(ec2_tag_filter.value, "type", null)
          value = lookup(ec2_tag_filter.value, "value", null)
        }
      }
    }
  }
  dynamic "ecs_service" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "ecs_service", [])
    content {
      cluster_name = lookup(ecs_service.value, "cluster_name", null)
      service_name = lookup(ecs_service.value, "service_name", null)
    }
  }
  dynamic "on_premises_instance_tag_filter" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "on_premises_instance_tag_filter", [])
    content {
      key   = lookup(on_premises_instance_tag_filter.value, "key", null)
      type  = lookup(on_premises_instance_tag_filter.value, "type", null)
      value = lookup(on_premises_instance_tag_filter.value, "value", null)
    }
  }
  dynamic "load_balancer_info" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "load_balancer_info", [])
    content {
      dynamic "target_group_pair_info" {
        for_each = lookup(load_balancer_info.value, "target_group_pair_info", [])
        content {
          dynamic "prod_traffic_route" {
            for_each = lookup(target_group_pair_info.value, "prod_traffic_route", [])
            content {
              listener_arns = lookup(prod_traffic_route.value, "listener_arns", null)
            }
          }
          dynamic "target_group" {
            for_each = lookup(target_group_pair_info.value, "target_group", [])
            content {
              name = lookup(target_group.value, "name", null)
            }
          }
        }
      }
    }
  }
  dynamic "trigger_configuration" {
    for_each = lookup(var.aws_codedeploy_deployment_group, "trigger_configuration", [])
    content {
      trigger_events     = lookup(trigger_configuration.value, "trigger_events", null)
      trigger_name       = lookup(trigger_configuration.value, "trigger_name", null)
      trigger_target_arn = lookup(trigger_configuration.value, "trigger_target_arn", null)
    }
  }
}
