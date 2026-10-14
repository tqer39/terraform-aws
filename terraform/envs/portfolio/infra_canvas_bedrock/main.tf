locals {
  infra_canvas_model_id = "amazon.nova-lite-v1:0"
}

# ローカルの SSO 管理者セッションから引き受ける、推論専用のロール。
# SSO ロールを再作成しても使えるよう suffix だけをワイルドカードにする。
resource "aws_iam_role" "infra_canvas_bedrock" {
  name                 = "infra-canvas-bedrock-local"
  description          = "Local Infra Canvas Bedrock inference only"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { AWS = "arn:aws:iam::${local.aws_account_id}:root" }
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${local.aws_account_id}:role/aws-reserved/sso.amazonaws.com/${local.region.apne1}/AWSReservedSSO_AdministratorAccess_*"
        }
      }
    }]
  })
  tags = { "${local.prefix}:product" = "infra-canvas" }
}

resource "aws_iam_role_policy" "infra_canvas_bedrock" {
  name = "invoke-selected-model"
  role = aws_iam_role.infra_canvas_bedrock.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "InvokeTokyoNovaLite"
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = ["arn:aws:bedrock:${local.region.apne1}::foundation-model/${local.infra_canvas_model_id}"]
      Condition = {
        StringEquals = { "aws:RequestedRegion" = local.region.apne1 }
      }
    }]
  })
}

output "infra_canvas_bedrock_role_arn" {
  description = "ローカルの infra-canvas AWS プロファイルで引き受ける Bedrock 専用ロール"
  value       = aws_iam_role.infra_canvas_bedrock.arn
}
