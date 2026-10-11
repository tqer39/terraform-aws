# terraform-aws

AWS リソースを Terraform で管理するリポジトリです。
環境ごとの構成を `terraform/envs/`、共通モジュールを `terraform/modules/` に置いています。

[![検証](https://github.com/tqer39/terraform-aws/actions/workflows/lefthook.yml/badge.svg)](https://github.com/tqer39/terraform-aws/actions/workflows/lefthook.yml)
[![Sandbox](https://github.com/tqer39/terraform-aws/actions/workflows/_terraform-aws-sandbox.yml/badge.svg)](https://github.com/tqer39/terraform-aws/actions/workflows/_terraform-aws-sandbox.yml)
[![Portfolio](https://github.com/tqer39/terraform-aws/actions/workflows/_terraform-aws-portfolio.yml/badge.svg)](https://github.com/tqer39/terraform-aws/actions/workflows/_terraform-aws-portfolio.yml)
[![Management](https://github.com/tqer39/terraform-aws/actions/workflows/_terraform-aws-management.yml/badge.svg)](https://github.com/tqer39/terraform-aws/actions/workflows/_terraform-aws-management.yml)

## 開発を始める

Git と [mise](https://mise.jdx.dev/installing-mise.html) を用意し、リポジトリのルートで実行します。

```bash
mise trust
mise install
mise run setup
mise run lint
mise run test
```

ツールのバージョンとタスクは [mise.toml](mise.toml) で管理します。
セットアップは npm 依存をインストールし、既存の pre-commit フックを Lefthook に置き換えます。
回帰テストには Python 3 と Git も必要です。詳しくは [開発手順](docs/development.ja.md)を参照してください。

## 変更とデプロイ

GitHub Flow で作業ブランチから PR を作成し、検証・レビュー後に `main` へマージします。
PR では AWS 認証なしで Terraform を静的検証します。
現行 CI の apply は `main` での手動実行が必要で、実行の有効化設定と plan の差分も条件になります。
詳細は [デプロイフロー](docs/deploy_flow/README.md)を参照してください。

**ローカルからのデプロイは原則禁止です。**
GitHub Actions は OIDC で AWS に認証します。認証情報と Terraform state はコミットしません。

## 構成とドキュメント

| 場所・資料 | 内容 |
| :--- | :--- |
| [環境構成](terraform/envs/) | `management`（全体管理）、`portfolio`、`sandbox`（検証） |
| [共通モジュール](terraform/modules/) | 用途別の部品、ドメイン、証明書、デプロイ用ロール |
| [開発手順](docs/development.ja.md) | 検証、エディタ、ツール更新、AI 共通ルールの管理 |
| [Terraform の運用](docs/terraform-operations.ja.md) | ローカル検証・plan、環境追加、モジュール化の方針 |
| [依存関係の可視化](docs/terraform-graph.ja.md) | GitHub Actions とローカルでのグラフ生成 |
| [GitHub Actions のサプライチェーン対策](docs/github-actions-security.ja.md) | 認証・権限・依存の固定と生成処理 |
| [共通開発ルール](docs/rules/overview.md) | 各 AI 開発ツール向けルールの原本 |
| [ADR](docs/adr/README.md) / [計画書](docs/plans/README.md) | 設計上の決定と移行作業の計画 |
