# これは何？

- Terraform の state ファイルを保存する s3 バケットを作成します。

## 使い方

```hcl
module "tfstate-s3-bucket" {
  source = "../../../usecases/base/terraform_tfstate_backend"

  bucket_name = バケット名
}
```

## outputs

- なし

## その他

### リソースの取り込み方

- 鶏卵のお話で、Terraform の state ファイル（`*.tfstate`）を保存する場所なので、通常のデプロイフローではリソースが作成できません。

### 方法.1 手作業でリソースを作成してから Terraform に Import

- リソースはじめは手作業でリソースの作成を行い、後から `terraform import` することで state を取り込めます。

```bash
# example
terraform -chdir=./terraform/environments/dev/base_apne1 import module.tfstate-s3-bucket.module.s3-bucket.this terraform-tfstate-tqer39-577523824419-ap-northeast-1
```

### 方法.2 ローカルから Terraform CLI でリソースを作成

- [README](../../../../README.md)の`ローカルから Terraform CLI を実行する方法`にある通り、ローカルから AWS SSO のロールで実行します。

## リファレンス

- [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [aws_s3_bucket_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl)
- [aws_s3_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning)
- [aws_s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)
