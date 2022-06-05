# これは何？

- GitHub Actions から AWS へアクセスするときに OIDC で認証をするための ID Provider を作成します。

## 使い方

```hcl
module "oidc-github-actions" {
  source = "../../../usecases/base/id_provider"
}
```

## outputs

- なし

## その他

### リソースの新規作成時の作業

- GitHub Actions で `terraform apply` をするときにこの ID Provider がないと、当該 AWS アカウントへの OIDC 認証ができず、そもそもこのリソースが存在しないと `terraform apply` ができません。
- 下記の方法のいずれかで、リソースを作成し、state を取り込みます。

#### 方法.1 ローカルから Terraform CLI でリソースを作成

- [README](../../../../README.md)の`ローカルから Terraform CLI を実行する方法`にある通り、ローカルから AWS SSO のロールで実行します。

#### 方法.2 手作業でリソースを作成してから Terraform に Import

- AWS マネジメントコンソールで手作業でリソースの作成を行います。
- 作成したリソースを `terraform import` することで state を取り込みます。

```bash
# example
aws_account_id=577523824419
env_name=management
tf_cd="./terraform/environments/${env_name}/base_apne1"
terraform -chdir="${tf_cd}" import module.oidc-github-actions-id-provider.aws_iam_openid_connect_provider.this \
  "arn:aws:iam::${aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
```

## リファレンス

- [aws_iam_openid_connect_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)
- [tls_certificate (Data Source)](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate)
- [http (Data Source)](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http)
