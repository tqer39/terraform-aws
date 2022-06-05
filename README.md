# private-lab

Private で使用している Terraform で構成可能なリソースをまとめる。

## GitHub Actions Status badges

| Name | Environment | Result |
| :--- | :--- | :--- |
| Linterなどによる検証 | pre-commit | ![pre-commit](https://github.com/tqer39/private-lab/actions/workflows/pre-commit.yml/badge.svg) |
| AWS 検証環境 | Sandbox | ![Terraform - sandbox](https://github.com/tqer39/private-lab/actions/workflows/terraform-aws-sandbox.yml/badge.svg) |
| AWS 全体管理 | Management | ![Terraform - management](https://github.com/tqer39/private-lab/actions/workflows/terraform-aws-management.yml/badge.svg) |

## Setup

### Homebrew

```bash
# install brew see: https://brew.sh/index_ja
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install software
brew bundle
```

### anyenv

#### zsh

```bash
anyenv init
anyenv install --init
echo 'eval "$(anyenv init -)"' >> ~/.zshrc
exec $SHELL -l
mkdir -p "$(anyenv root)/plugins"
git clone https://github.com/znz/anyenv-update.git "$(anyenv root)/plugins/anyenv-update"
```

#### fish

```bash
anyenv init - fish | source
anyenv install --init
set -Ux fish_user_paths $HOME/.anyenv/bin $fish_user_paths
echo 'set -x PATH ~/.anyenv/bin $PATH' >> ~/.config/fish/config.fish
echo 'eval (anyenv init - | source)' >> ~/.config/fish/config.fish
exec fish -l
mkdir -p (anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git (anyenv root)/plugins/anyenv-update
which anyenv
```

### tfenv

```bash
anyenv install tfenv
```

### Terraform

```bash
tfenv install
```

### Session Manager Plugin

see: [(オプション) AWS CLI 用の Session Manager プラグインをインストールする](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

#### Linux (Debian | amd64)

```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
rm -rf session-manager-plugin.deb
```

### pre-commit

```bash
# setup
pre-commit install --install-hooks
```

## 新しい環境の作成方法

手動で s3 バケットを作成。
リソースを作成。

```txt
.github/workflows/terraform-<環境名>.yml
.github/labeler.yml
terraform/environments/<環境名>/base/main.tf
terraform/environments/<環境名>/base/provider.tf
terraform/environments/<環境名>/base/terraform.tf
terraform/environments/<環境名>/base/shared-locals.tf
terraform/environments/<環境名>/shared/locals.tf
```

```zsh
# https://xxxxx.awsapps.com/start#/
export AWS_ACCESS_KEY_ID="XXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXX"
export AWS_SESSION_TOKEN="XXXXXXXXXX"

terraform -chdir=terraform/environments/<環境名>/base init
```

手動で作成した s3 バケットを import。

```zsh
$TF_PATH="terraform/environments/<環境名>/base"
terraform -chdir="$TF_PATH" import module.terraform-backend.module.s3-bucket.aws_s3_bucket.this <バケット名>
terraform -chdir="$TF_PATH" import module.terraform-backend.module.s3-bucket.aws_s3_bucket_acl.this <バケット名>
terraform -chdir="$TF_PATH" import module.terraform-backend.module.s3-bucket.aws_s3_bucket_public_access_block.this <バケット名>
terraform -chdir="$TF_PATH" import module.terraform-backend.module.s3-bucket.aws_s3_bucket_versioning.this <バケット名>
```

OIDC 関連のリソースの新規作成と s3 バケットのパラメータ更新を行います。

```zsh
$TF_PATH="terraform/environments/<環境名>/base"
terraform -chdir="$TF_PATH" fmt
terraform -chdir="$TF_PATH" validate
terraform -chdir="$TF_PATH" plan
terraform -chdir="$TF_PATH" apply -auto-approve
```
