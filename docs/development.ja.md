# 開発手順

[README](../README.md) / [Terraform の運用](terraform-operations.ja.md)

## セットアップ

Git と [mise](https://mise.jdx.dev/installing-mise.html) を事前にインストールし、
リポジトリのルートで次のコマンドを実行します。

```bash
mise trust
mise install
mise run setup
```

ツールとタスクは [mise.toml](../mise.toml) で管理します。
`mise run setup` は lockfile に従って `npm ci --ignore-scripts` を実行し、
Lefthook の Git フックを設定します。既存の pre-commit フックは置き換えます。
Homebrew の導入やシェル設定は個人の環境で管理してください。anyenv と tfenv は不要です。
CI の [Repository Setup](../.github/workflows/repository-setup.yml) は macOS・Linux で同じタスクを検証します。

## 検証

リポジトリのルートで実行します。回帰テストには Python 3 と Git も必要です。

```bash
mise run lint
mise run test

# Terraform の変更時に全環境を検証
mise run terraform-validate
```

- lint は全ファイル、コミット時のフックはステージ済みファイルを検証します。
- 検証はファイルを自動修正しません。チェックの定義は [lefthook.yml](../lefthook.yml) を参照してください。
- 安全チェックの Python 依存は uv が初回実行時に取得します。pre-commit の CLI は不要です。
- 512 KiB のサイズ制限は生成物 `package-lock.json` を除いて適用します。
- `mise run test` は Python の回帰テストと Renovate 設定の Node.js テストを実行します。
- `mise run terraform-validate` は backend 接続と AWS 認証なしで fmt・init・validate を実行します。
  provider のダウンロードにはネットワーク接続が必要です。詳細は [Terraform の運用](terraform-operations.ja.md)を参照してください。

## エディタとツールの更新

[.editorconfig](../.editorconfig) に従って編集します。
必要に応じて [EditorConfig の対応プラグイン](https://editorconfig.org/#download)を導入してください。

ツールのバージョンを変更するときは `mise.toml` と関連するバージョンファイルを更新し、
`mise install` と検証を実行してください。Node.js は `.node-version`、
Terraform は `.terraform-version` と同じバージョンにします。
対象ルートの provider 制約と `.terraform.lock.hcl` も確認し、無関係な更新を避けてください。

## GitHub Actions の SHA 固定

`pinact` は `mise.toml` でバージョンを固定しています。
セットアップ後、リポジトリのルートで実行します。

```bash
# ワークフローと composite action の参照を SHA に固定
mise exec -- pinact run

# CI と同じ、API に接続しない固定形式の検証
mise exec -- pinact run --fix=false --no-api --exclude '^docker://'
```

変更後は差分を確認してコミットしてください。
コンテナのダイジェスト固定などの詳細は [GitHub Actions のサプライチェーン対策](github-actions-security.ja.md)を参照してください。

## AI 開発ツールの共通ルール

Codex、Claude Code、GitHub Copilot、Cursor のルールとスキルは
[共通ルール](rules/overview.md)、[スキルの生成元](../.rulesync/skills/)、[rulesync 設定](../rulesync.jsonc) で管理します。
リポジトリのルートで、セットアップ済みの Node.js と npm を使用します。
macOS・Linux・Windows で同じ npm コマンドを実行できます。

```bash
mise exec -- npm run rules:generate
mise exec -- npm run rules:check
```

| ツール | 生成ファイル |
| :--- | :--- |
| Codex | `AGENTS.md` |
| Claude Code | `AGENTS.md`（Codex と共用） |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/overview.mdc` |

このリポジトリではルートの `CLAUDE.md` を生成せず、Claude Code も `AGENTS.md` を参照します。
共通ルールの生成対象は Codex、GitHub Copilot、Cursor とし、Claude Code のスキル生成は維持します。
ルールを変更するときは `docs/rules/overview.md` を編集し、再生成してください。
スキルの詳細な手順は `docs/rules/<スキル名>.md` に置きます。
`.rulesync/skills/<スキル名>/SKILL.md` には適用条件と原本への参照を記述し、同じコマンドで再生成します。
各ツールのスキルは実行前に原本を読み、手順を複製しません。
スキル専用の原本は YAML メタデータに `targets: []` を指定し、ルールの生成対象から除外します。
`update-gitignore` は Toptal の最新テンプレートから `.gitignore` の生成ブロックを更新するスキルです。
手順の原本は [.gitignore の更新手順](rules/update-gitignore.md) です。
生成先は Codex の `.agents/skills/`、Claude Code の `.claude/skills/`、
GitHub Copilot の `.github/skills/`、Cursor の `.cursor/skills/` です。
生成元・設定・生成ファイルを一緒にコミットします。生成ファイルは直接編集しません。
CI の `rulesync` ジョブで同期漏れを検出します。
個人用の上書き設定 `rulesync.local.jsonc` は Git の管理対象外です。
