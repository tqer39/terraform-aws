locals {
  discord_state_key        = "kazokubi/infra/discord.tfstate"
  discord_workspace_prefix = "kazokubi/infra/discord-workspaces"
  discord_bucket_arn       = "arn:aws:s3:::${local.tfstate_bucket_name.apne1}"
  discord_roles = {
    plan = [
      "repo:${local.organization}/kazokubi:pull_request",
      "repo:${local.organization}/kazokubi:ref:refs/heads/main",
    ]
    apply = ["repo:${local.organization}/kazokubi:ref:refs/heads/main"]
  }
}

resource "aws_iam_role" "discord" {
  for_each = local.discord_roles
  name     = "${local.aws_env_name}-kazokubi-discord-${each.key}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = "arn:aws:iam::${local.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = each.value
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "discord" {
  for_each = local.discord_roles
  name     = "discord-state"
  role     = aws_iam_role.discord[each.key].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [local.discord_bucket_arn]
        Condition = {
          StringEquals = {
            "s3:prefix" = [local.discord_state_key, local.discord_workspace_prefix]
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = each.key == "apply" ? ["s3:GetObject", "s3:PutObject"] : ["s3:GetObject"]
        Resource = ["${local.discord_bucket_arn}/${local.discord_state_key}"]
      }
      ], each.key == "apply" ? [{
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["${local.discord_bucket_arn}/${local.discord_state_key}.tflock"]
    }] : [])
  })
}

output "discord_role_arns" {
  description = "kazokubi の Repository Secrets に登録する plan/apply 用ロール ARN"
  value       = { for name, role in aws_iam_role.discord : name => role.arn }
}
