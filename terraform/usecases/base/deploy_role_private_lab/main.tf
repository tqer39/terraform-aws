resource "aws_iam_role" "this" {
  name = "${var.env_name}-${var.repository}-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRoleWithWebIdentity"
        ]
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:${var.organization}/${var.repository}:*"
          }
        }
      },
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::577523824419:role/management-private-lab-deploy"
        }
      }
    ]
  })
  managed_policy_arns = [
    aws_iam_policy.this.arn
  ]
  depends_on = [
    aws_iam_policy.this
  ]
}

resource "aws_iam_policy" "this" {
  name = "${var.env_name}-${var.repository}-deploy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowSpecifics"
        Action = [
          "lambda:*",
          "apigateway:*",
          "ec2:*",
          "rds:*",
          "s3:*",
          "sns:*",
          "states:*",
          "ssm:*",
          "sqs:*",
          "iam:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*",
          "cloudfront:*",
          "route53:*",
          "ecr:*",
          "logs:*",
          "ecs:*",
          "application-autoscaling:*",
          "events:*",
          "elasticache:*",
          "es:*",
          "kms:*",
          "dynamodb:*",
          "kinesis:*",
          "firehose:*",
          "elasticbeanstalk:*",
          "cloudformation:*",
          "acm:*",
          "organizations:*",
          "sso:*",
          "identitystore:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "DenySpecifics"
        Action = [
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
}
