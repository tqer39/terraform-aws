# Terraform の運用

[README](../README.md) / [開発手順](development.ja.md) / [デプロイフロー](deploy_flow/README.md)

## 構成とモジュール化

[terraform/envs/](../terraform/envs/) に環境ごとのルート構成、
[terraform/modules/](../terraform/modules/) に共通部品と用途別のモジュールを置きます。
各ルートの `terraform.tf` と `.terraform.lock.hcl` で Terraform・provider の制約と選択バージョンを確認してください。

次のリソースは、直接記述する方針です。

| リソース | 理由 |
| :--- | :--- |
| `aws_iam_role_policy_attachment` | パラメータが少なく、モジュール化による利点が小さい |
| `aws_route53_record` | レコードの種類が多く、汎用モジュールの作成・維持にかかるコストが大きい |

モジュールの入出力は各ディレクトリの `USAGE.md` を参照してください。
生成方法は [GitHub Actions のサプライチェーン対策](github-actions-security.ja.md#pr-での生成処理)に記載しています。

## State のロック

全環境の S3 backend で `use_lockfile = true` を設定し、同じ state への同時書き込みを防ぎます。
ロックには state のキーに `.tflock` を付けた S3 オブジェクトを使用します。
実行ロールには、このオブジェクトへの `s3:GetObject`、`s3:PutObject`、
`s3:DeleteObject` 権限が必要です。
portfolio と sandbox の実行ロールは既存の `s3:*` 権限で対応しています。
management の IAM ポリシーはこのリポジトリの管理対象外のため、利用前に権限を確認してください。
詳細は [S3 backend の公式ドキュメント](https://developer.hashicorp.com/terraform/language/backend/s3)を参照してください。

すでに初期化した作業ディレクトリでは、対象環境の AWS 認証を用意して
`terraform init -reconfigure -lockfile=readonly` を実行します。
state の保存先は変わらないため、state の移行は不要です。
GitHub Actions はチェックアウト後に `terraform init` を実行するため、新しい設定を読み込みます。

## AWS 認証なしの検証

[開発用セットアップ](development.ja.md#セットアップ)後、リポジトリのルートで実行します。

```bash
mise run terraform-validate
```

[検証スクリプト](../scripts/validate-terraform.sh)は全ルートを fmt・init・validate で検証します。
provider はダウンロードしますが、backend 接続や AWS 認証は行いません。
lockfile は読み取り専用で扱います。依存の取得にはネットワーク接続が必要です。
validate は構成の整合性を確認するための検証で、実環境に対する plan の代わりにはなりません。

特定のルートだけを検証する場合は、次のように実行します。

```bash
mise exec -- terraform -chdir=terraform/envs/portfolio/base_apne1 fmt -check -recursive -diff
mise exec -- terraform -chdir=terraform/envs/portfolio/base_apne1 init -backend=false -input=false -lockfile=readonly
mise exec -- terraform -chdir=terraform/envs/portfolio/base_apne1 validate
```

根拠は [Terraform の validate リファレンス](https://developer.hashicorp.com/terraform/cli/commands/validate)を参照してください。

## AWS 接続が必要な操作

plan には対象アカウントの権限と S3 backend へのアクセスが必要です。
[aws-vault の公式手順](https://github.com/ByteNess/aws-vault#installing)に従って導入し、
組織で許可された SSO profile を `~/.aws/config` に設定してください。
アカウント ID・SSO ロール・リージョンは対象環境に合わせます。
認証情報をリポジトリやコマンド例へ貼り付けないでください。

```bash
# portfolio の権限を持つ profile 名に置き換える
TF_AWS_PROFILE='<SSO profile 名>'
TF_ROOT='terraform/envs/portfolio/base_apne1'

mise exec -- aws-vault exec "$TF_AWS_PROFILE" -- terraform -chdir="$TF_ROOT" init -input=false -lockfile=readonly
mise exec -- aws-vault exec "$TF_AWS_PROFILE" -- terraform -chdir="$TF_ROOT" plan
```

**ローカルからのデプロイは原則禁止です。** apply は [GitHub Actions の手順](deploy_flow/README.md)に従います。
import・destroy・state の変更も通常の検証には含めません。必要な場合は対象と手順を別途確認してください。

## 新しい環境・ルートの追加

既存環境の名前や backend をそのまま流用せず、次の項目を確認します。

1. 対象アカウント、リージョン、管理対象と、既存構成への影響を決めます。
2. `terraform/envs/<環境>/<ルート>/` に構成を用意し、共有 locals とモジュールの参照を設定します。
3. S3 backend のバケット、state key、アクセス権限を決めます。
   新しい backend の初回構築や既存リソースの import は、通常の PR 検証と分けて手順を作成します。
4. GitHub Actions の OIDC ロールと信頼ポリシー、対象アカウントを確認します。
5. [デプロイ対象一覧](../.github/workflows/deploy_pipeline/)と環境別ワークフローを更新します。
   新しい環境名を増やす場合は、[対象選択スクリプト](../.github/scripts/terraform_matrix.py)と
   [グラフ生成ワークフロー](../.github/workflows/terraform-graph.yml)の許可する環境名も更新します。
6. fmt・validate・回帰テストと CI を確認し、plan をレビューしてからデプロイします。

構成変更・移行の計画は [計画書の規約](plans/README.md)に従って管理します。
古い一括 import コマンドやローカル apply の例は、現行モジュールと一致するか確認せずに再利用しないでください。

## 任意の追加ツール

これらのツールは必要な場合に個人の環境へ導入します。通常のセットアップや検証ではインストールしません。

| ツール | 用途 | 導入方法 |
| :--- | :--- | :--- |
| aws-vault | SSO profile を使ったローカル AWS 認証 | [公式手順](https://github.com/ByteNess/aws-vault#installing) |
| Session Manager plugin | AWS Systems Manager のセッション接続 | [AWS 公式手順](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) |
| Rancher Desktop | ローカルのコンテナ環境 | [公式の OS 別手順](https://docs.rancherdesktop.io/getting-started/installation/) |
| Graphviz | Terraform の依存関係の可視化 | [グラフ生成手順](terraform-graph.ja.md#ローカルで生成する) |
