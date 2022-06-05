data "http" "github-actions-openid-configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

data "tls_certificate" "github-actions" {
  url = jsondecode(data.http.github-actions-openid-configuration.body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github-actions.certificates[0].sha1_fingerprint]
  url             = "https://token.actions.githubusercontent.com"
}
