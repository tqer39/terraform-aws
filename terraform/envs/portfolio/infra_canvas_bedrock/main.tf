locals {
  infra_canvas_model_id    = "openai.gpt-5.6-luna"
  infra_canvas_profile_arn = "arn:aws:bedrock:${local.region.apne1}:${local.aws_account_id}:inference-profile/global.${local.infra_canvas_model_id}"
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
  name = "invoke-gpt-5-6-luna"
  role = aws_iam_role.infra_canvas_bedrock.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InvokeSelectedProfile"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = [local.infra_canvas_profile_arn]
        Condition = {
          StringEquals = { "aws:RequestedRegion" = local.region.apne1 }
        }
      },
      {
        # OpenAI の bedrock-runtime 呼び出しには default project も必要。
        Sid      = "InvokeDefaultProject"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = ["arn:aws:bedrock:${local.region.apne1}:${local.aws_account_id}:project/default"]
        Condition = {
          StringEquals = { "aws:RequestedRegion" = local.region.apne1 }
        }
      },
      {
        Sid      = "InvokeRegionalModelThroughProfile"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = ["arn:aws:bedrock:${local.region.apne1}::foundation-model/${local.infra_canvas_model_id}"]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion"         = local.region.apne1
            "bedrock:InferenceProfileArn" = local.infra_canvas_profile_arn
          }
        }
      },
      {
        Sid      = "InvokeGlobalModelThroughProfile"
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = ["arn:aws:bedrock:::foundation-model/${local.infra_canvas_model_id}"]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion"         = "unspecified"
            "bedrock:InferenceProfileArn" = local.infra_canvas_profile_arn
          }
        }
      }
    ]
  })
}

output "infra_canvas_bedrock_role_arn" {
  description = "ローカルの infra-canvas AWS プロファイルで引き受ける Bedrock 専用ロール"
  value       = aws_iam_role.infra_canvas_bedrock.arn
}
