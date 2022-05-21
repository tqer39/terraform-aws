resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "aws-artifact-account-sync.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "config.amazonaws.com",
    "controltower.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]
  feature_set = "ALL"
}
