---
root: true
targets: ["*"]
description: "terraform-aws の共通開発ルール"
cursor:
  alwaysApply: true
  globs: []
---

# terraform-aws の開発ルール

このファイルは rulesync で生成されます。変更は `docs/rules/overview.md` に加え、
`npm run rules:generate` で全ツール向けに再生成してください。

## 基本方針

- 常に日本語で回答してください。
- 速度よりも正確性と完全性を優先し、編集前に適用される指示と関連コードを読んでください。
- 複雑な作業では期待する動作と検証条件を明確にし、実装から検証まで完了させてください。
- 無関係なユーザーの変更を保持し、根本原因を修正し、変更範囲を依頼内容に絞ってください。
- ツールやライブラリのバージョンに依存する動作は現在の一次情報を確認し、検証済みの事実と推測を区別してください。
- 意味のある動作変更には回帰テストを追加し、実装をなぞるだけのテストは追加しないでください。
- 最終差分をレビューし、回帰・要件漏れ・不要な変更がないか確認してください。
- 検証結果と残る制約を正確に報告してください。

## リポジトリ構成と Terraform

- AWS リソースを Terraform で管理するリポジトリです。
- `terraform/envs/` に環境ごとの構成、`terraform/modules/` に共通部品と用途別のモジュールがあります。
- 対象ディレクトリの Terraform・provider バージョンと `.terraform.lock.hcl` を確認し、無関係な更新を避けてください。
- GitHub Flow を使用し、`main` へのマージで GitHub Actions の `terraform apply` が実行されます。
- ローカルからのデプロイは原則禁止です。明示的な依頼なしに `terraform apply`、`destroy`、state の変更を実行しないでください。
- GitHub Actions の AWS 認証には OIDC を使用します。認証情報や Terraform state をコミットしないでください。
- 変更した Terraform は `terraform fmt -check` と、初期化済みの対象ディレクトリで `terraform validate` を検証してください。
- 認証情報や backend が必要で検証できない場合は、その制約を報告してください。

## ルールとスキルの管理

- LLM の共通ルールの原本は `docs/rules/` に置いてください。
- 各ツールのルールとスキルは rulesync で生成し、生成ファイルを直接編集しないでください。
- スキルの原本は `.rulesync/skills/<スキル名>/SKILL.md` に置き、適用条件と手順を記述してください。

## ドキュメントと検証

- ドキュメントは日本語で記述し、ADR は `docs/adr/README.md`、計画書は `docs/plans/README.md` の規約に従ってください。
- Python の回帰テストは `python3 -m unittest discover -s tests -p 'test_*.py'` で実行してください。
- lint は `lefthook.yml` に従い、`mise run lint` で検証してください。
- 共通ルールの変更後は生成元と生成ファイルを一緒にコミットし、`npm run rules:check` で同期状態を検証してください。
