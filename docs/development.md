# 開発手順

[README](../README.md) / [Terraform の運用](terraform-operations.md)

## セットアップ

Git と [mise](https://mise.jdx.dev/installing-mise.html) を事前にインストールし、
リポジトリのルートで次のコマンドを実行します。

```bash
mise trust
mise run bootstrap
```

ツールと固有タスクの正本は [.standards/mise.project.toml](../.standards/mise.project.toml) です。
[mise.toml](../mise.toml) は生成物です。
`mise run bootstrap` は mise 経由で Go 1.27.4 を取得し、dev-standards 0.4.19 を
`.standards/cache/bin` に配置してから既存の `setup` タスクを実行します。
`mise run setup` は lockfile に従って `npm ci --ignore-scripts` を実行し、
Lefthook の Git フックを設定します。既存の pre-commit フックは置き換えます。
Homebrew の導入やシェル設定は個人の環境で管理してください。anyenv と tfenv は不要です。
CI の [Repository Setup](../.github/workflows/repository-setup.yml) は macOS・Linux で同じタスクを検証します。

## 検証

リポジトリのルートで実行します。回帰テストには Python 3 と Git も必要です。

```bash
mise run check

# AWS に接続しないモックテストだけを実行
mise run terraform-test

# 変更した環境だけをすぐ検証
mise run terraform-validate terraform/envs/sandbox/test-statement

# Terraform の変更時に全環境を検証
mise run terraform-validate
```

- lint は全ファイル、コミット時のフックはステージ済みファイルを検証します。
- 検証はファイルを自動修正しません。チェックの定義は [lefthook.yml](../lefthook.yml) を参照してください。
- 安全チェックの Python 依存は uv が初回実行時に取得します。pre-commit の CLI は不要です。
- 512 KiB のサイズ制限は生成物 `package-lock.json` を除いて適用します。
- `mise run test` は Python の回帰テストと Renovate 設定の Node.js テストを実行します。
- `mise run terraform-validate` は backend 接続と AWS 認証なしで fmt・init・validate を実行します。
  provider のダウンロードにはネットワーク接続が必要です。詳細は [Terraform の運用](terraform-operations.md)を参照してください。

## エディタとツールの更新

[.editorconfig](../.editorconfig) に従って編集します。
必要に応じて [EditorConfig の対応プラグイン](https://editorconfig.org/#download)を導入してください。

ツールやタスクを変更するときは `.standards/mise.project.toml` を更新し、
次の手順で生成物を更新して検証してください。
`--upgrade` はツール一覧のロック更新を明示します。plan と apply は同じ更新先の CLI を使います。

```bash
mise exec -- dev-standards plan --upgrade --output .standards/plans/update.json
mise exec -- dev-standards apply --plan .standards/plans/update.json
mise run bootstrap
mise run check
```

計画に差分がある場合、plan は終了コード1になります。同じ計画の保存先は再利用しません。
ローカルと GitHub Actions の両方で mise を使用します。
Terraform 各環境の `required_version` は互換性の制約として維持し、Renovate で mise の正本とモック用の構成も一緒に更新します。
対象ルートの provider 制約と `.terraform.lock.hcl` も確認し、無関係な更新を避けてください。

Renovate は生成物の `mise.toml` を直接変更しません。
ツールの正本を更新した PR は、担当者が上記の計画と適用を実行し、生成物とロックを同じ PR に含めます。
同期前の CI は `standards:check` で失敗します。古い実行系のまま検証を通すことはありません。

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
コンテナのダイジェスト固定などの詳細は [GitHub Actions のサプライチェーン対策](github-actions-security.md)を参照してください。

mise-action の `version` は GitHub release のタグと同じ `v2026.11.5` 形式にします。
Renovate が release API を正確なタグで検索できるよう、接頭辞の `v` は省略しません。
OS ごとの `version` と `sha256` は同じ step の入力に直接記述し、Renovate が組として抽出できるようにします。
CI の準備処理は Linux x64 と macOS ARM64 を検証対象とし、対応するチェックサムがない runner は先に拒否します。
共通の setup-node と setup-terraform action は Linux x64 向けです。

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

## 技術調査をすぐ検証する

`tests/terraform` は backend を持たず、モック AWS provider と `command = plan` を使います。
S3 の公開アクセス遮断など、クラウドにリソースを作らず確認できる仕様をここで検証します。
新しい調査を追加するときも実 provider へ接続せず、モックを明示してください。
provider のスキーマ検証は行いますが、実 AWS API の挙動や権限は確認できません。

初回の `init` は provider を取得します。以後は lockfile の固定版を再利用します。
全体の `check` は lint、整形確認、Python・Node.js の回帰テスト、モックテスト、
全14環境の backend 無効化 init・validate を実行します。
macOS と Linux を対象とし、Windows は未検証です。

`.standards` の設定整合性は `standards:check`、実際の検査は `standards:verify` で確認できます。
`.gitignore` の独自設定は `.standards/gitignore.local` が正本です。
採用元テンプレートの改行と空白はハッシュ照合のため維持し、通常の空白修正から除外します。
