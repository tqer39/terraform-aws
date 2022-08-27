resource "aws_codepipeline" "this" {
  name     = lookup(var.aws_codepipeline, "name", null)
  role_arn = lookup(var.aws_codepipeline, "role_arn", null)
  dynamic "artifact_store" {
    for_each = lookup(var.aws_codepipeline, "artifact_store", [])
    content {
      location = lookup(artifact_store.value, "location", null)
      region   = lookup(artifact_store.value, "region", null)
      type     = lookup(artifact_store.value, "type", null)
      dynamic "encryption_key" {
        for_each = lookup(artifact_store.value, "encryption_key", [])
        content {
          id   = lookup(encryption_key.value, "id", null)
          type = lookup(encryption_key.value, "type", null)
        }
      }
    }
  }
  dynamic "stage" {
    for_each = lookup(var.aws_codepipeline, "stage", [])
    content {
      name = lookup(stage.value, "name", null)
      dynamic "action" {
        for_each = lookup(stage.value, "action", [])
        content {
          category         = lookup(action.value, "category", null)
          input_artifacts  = lookup(action.value, "input_artifacts", null)
          name             = lookup(action.value, "name", null)
          namespace        = lookup(action.value, "namespace", null)
          output_artifacts = lookup(action.value, "output_artifacts", null)
          owner            = lookup(action.value, "owner", null)
          provider         = lookup(action.value, "provider", null)
          region           = lookup(action.value, "region", null)
          run_order        = lookup(action.value, "run_order", null)
          role_arn         = lookup(action.value, "role_arn", null)
          version          = lookup(action.value, "version", null)
          dynamic "configuration" {
            for_each = lookup(action.value, "configuration", [])
            content {
              ActionMode       = lookup(configuration.value, "ActionMode", null)
              BranchName       = lookup(configuration.value, "BranchName", null)
              Capabilities     = lookup(configuration.value, "Capabilities", null)
              ConnectionArn    = lookup(configuration.value, "ConnectionArn", null)
              FullRepositoryId = lookup(configuration.value, "FullRepositoryId", null)
              OutputFileName   = lookup(configuration.value, "OutputFileName", null)
              ProjectName      = lookup(configuration.value, "ProjectName", null)
              StackName        = lookup(configuration.value, "StackName", null)
              TemplatePath     = lookup(configuration.value, "TemplatePath", null)
            }
          }
        }
      }
    }
  }
}
