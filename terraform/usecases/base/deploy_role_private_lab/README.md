# これは何？

- GitHub Actions から AWS へアクセスするときに使用する OIDC 認証の ID Provider にアクセスする IAM ロールを作成します。
- [private-lab](https://github.com/tqer39/private-lab) 用です。

## 使い方

```hcl
module "deploy-role" {
  source = "../../../usecases/base/deploy_role_private_lab"

  aws_account_id = AWS アカウント ID
  env_name       = 環境名
  organization   = tqer39
  repository     = private-lab
}
```

## outputs

- なし

## その他

### リソースの新規作成時の作業

- GitHub Actions で `terraform apply` をするときに AWS の認証をするためのロールなので、そもそもこのリソースが存在しないと `terraform apply` ができません。
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
repository=private-lab
tf_cd=./terraform/environments/dev/base_apne1
terraform -chdir="${tf_cd}" import module.deploy-role.module.iam-role.aws_iam_role.this \
  "${env_name}-${repository}-deploy"
terraform -chdir="${tf_cd}" import module.deploy-role.module.iam-policy.aws_iam_policy.this \
  "arn:aws:iam::${aws_account_id}:policy/${env_name}-${repository}-deploy"
terraform -chdir="${tf_cd}" import module.deploy-role.aws_iam_role_policy_attachment.this \
  "${env_name}-${repository}-deploy/arn:aws:iam::${aws_account_id}:policy/${env_name}-${repository}-deploy"
```

#### ポリシー作成時の注意点

- [README](../../../../README.md)の`IAM Policy`に準拠します。

## リファレンス

- [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
