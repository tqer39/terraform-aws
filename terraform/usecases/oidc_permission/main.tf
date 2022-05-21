module "oidc" {
  source = "../../modules/iam_role/oidc"

  aws_account_id = var.aws_account_id
  env_name       = var.env_name
  organization   = var.organization
  repository     = var.repository
}

resource "aws_iam_policy" "github-actions" {
  description = ""
  name        = "${var.env_name}-${var.repository}-deploy"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "AllowSpecifics"
          Action = [
            "apigateway:*",
            "application-autoscaling:*",
            "autoscaling:*",
            "cloudformation:*",
            "cloudfront:*",
            "cloudwatch:*",
            "dynamodb:*",
            "ec2:*",
            "ecr:*",
            "ecs:*",
            "events:*",
            "elasticache:*",
            "elasticbeanstalk:*",
            "elasticloadbalancing:*",
            "es:*",
            "firehose:*",
            "iam:*",
            "kinesis:*",
            "kms:*",
            "lambda:*",
            "logs:*",
            "rds:*",
            "s3:*",
            "sns:*",
            "sqs:*",
            "ssm:*",
            "states:*",
            "organizations:*",
            "route53:*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Sid = "DenySpecifics"
          Action = [
            # "iam:*User*",
            "iam:*Login*",
            "iam:*Group*",
            "aws-portal:*",
            "budgets:*",
            "config:*",
            "directconnect:*",
            "aws-marketplace:*",
            "aws-marketplace-management:*",
            "ec2:*ReservedInstances*"
          ]
          Effect   = "Deny"
          Resource = "*"
        }
      ]
  })

  depends_on = [
    module.oidc
  ]
}

resource "aws_iam_role_policy_attachment" "github-actions" {
  role       = module.oidc.name
  policy_arn = aws_iam_policy.github-actions.arn

  depends_on = [
    module.oidc,
    aws_iam_policy.github-actions
  ]
}
