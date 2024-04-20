module "tfstate_s3_bucket" {
  source = "../../../modules/terraform_tfstate_bucket"

  bucket_name = local.tfstate_bucket_name.apne1
}

module "oidc_github_actions_id_provider" {
  source = "../../../modules/id_provider"
}

# module "deploy_role" {
#   source = "../../../usecases/deploy_role/terraform_aws"

#   aws_account_id = local.aws_account_id
#   aws_env_name   = local.aws_env_name
#   organization   = local.organization
#   repository     = local.repository
#   depends_on = [
#     aws_iam_policy.deploy_allow_specifics,
#     aws_iam_policy.deploy_deny_specifics,
#   ]
# }

# data "aws_iam_policy_document" "deploy_allow_specifics" {
#   statement {
#     sid = "AllowSpecifics"
#     actions = [
#       "lambda:*",
#       "apigateway:*",
#       "ec2:*",
#       "rds:*",
#       "s3:*",
#       "sns:*",
#       "states:*",
#       "ssm:*",
#       "sqs:*",
#       "iam:*",
#       "elasticloadbalancing:*",
#       "autoscaling:*",
#       "cloudwatch:*",
#       "cloudfront:*",
#       "route53:*",
#       "ecr:*",
#       "logs:*",
#       "ecs:*",
#       "application-autoscaling:*",
#       "events:*",
#       "elasticache:*",
#       "es:*",
#       "kms:*",
#       "dynamodb:*",
#       "kinesis:*",
#       "firehose:*",
#       "elasticbeanstalk:*",
#       "cloudformation:*",
#       "acm:*",
#       "organizations:*",
#       "sso:*",
#       "identitystore:*",
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "deploy_allow_specifics" {
#   name   = "deploy-allow-specifics"
#   policy = data.aws_iam_policy_document.deploy_allow_specifics.json
# }

# data "aws_iam_policy_document" "deploy_deny_specifics" {
#   statement {
#     actions = [
#       "iam:*Login*",
#       "iam:*Group*",
#       "aws-portal:*",
#       "budgets:*",
#       "config:*",
#       "directconnect:*",
#       "aws-marketplace:*",
#       "aws-marketplace-management:*",
#       "ec2:*ReservedInstances*"
#     ]
#     effect    = "Deny"
#     resources = ["*"]
#     sid       = "DenySpecifics"
#   }
# }

# resource "aws_iam_policy" "deploy_deny_specifics" {
#   name   = "deploy-deny-specifics"
#   policy = data.aws_iam_policy_document.deploy_deny_specifics.json
# }

removed {
  from = aws_iam_policy.deploy_allow_specifics
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_policy.deploy_deny_specifics
  lifecycle {
    destroy = false
  }
}

removed {
  from = module.deploy_role.aws_iam_role.this
  lifecycle {
    destroy = false
  }
}
