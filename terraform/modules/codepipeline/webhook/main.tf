resource "aws_codepipeline_webhook" "this" {
  name            = lookup(var.aws_codepipeline_webhook, "name", null)
  authentication  = lookup(var.aws_codepipeline_webhook, "authentication", null)
  target_action   = lookup(var.aws_codepipeline_webhook, "target_action", null)
  target_pipeline = lookup(var.aws_codepipeline_webhook, "target_pipeline", null)
  dynamic "authentication_configuration" {
    for_each = lookup(var.aws_codepipeline_webhook, "authentication_configuration", [])
    content {
      secret_token = lookup(authentication_configuration.value, "secret_token", null)
    }
  }
  dynamic "filter" {
    for_each = lookup(var.aws_codepipeline_webhook, "filter", [])
    content {
      json_path    = lookup(filter.value, "json_path", null)
      match_equals = lookup(filter.value, "match_equals", null)
    }
  }
}
