module "iam-role" {
  source = "../../../modules/iam/role"

  aws_iam_role = {
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
        }
      ]
    })
    managed_policy_arns = [
      module.iam-policy.arn
    ]
  }
  depends_on = [
    module.iam-policy
  ]
}

module "iam-policy" {
  source = "../../../modules/iam/policy"

  aws_iam_policy = {
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
            "organizations:*"
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
}
