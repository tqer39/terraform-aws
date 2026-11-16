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

## AWS Emulator で API の往復を検証

Docker Engine と Docker CLI を用意し、次を実行します。
既存の `bootstrap` は Docker のインストールや起動を行いません。

```bash
mise run aws-emulator-test
```

公式の [AWS Emulator](https://github.com/aws/aws-emulator) 1.0.385 を Docker で起動し、
DynamoDB テーブルと SQS キューを作成して API から読み戻します。
Terraform の `test` が削除まで実行し、成功・失敗のどちらでも専用コンテナを終了します。
通常の `check` は Docker を要求しません。
CI では専用の AWS Emulator ワークフローを手動実行でき、検証環境の関連ファイルを変更した PR・main への push でも起動します。
これは Emulator と provider の API 互換性を確かめる調査用の検証です。既存モジュールの回帰テストとは区別します。

macOS・Linux の Docker の ARM64・x86_64 に対応するパッケージを選択します。
Windows はリポジトリの検証対象外です。初回はイメージと provider の取得に通信が必要です。
再実行では Docker のイメージと provider のキャッシュを使います。並行実行時の init は直列化します。
Emulator は 2 GiB のメモリ上限、ループバックだけの公開、署名認証と証明書検証を有効にし、telemetry を無効にします。

検証用の Terraform 構成は [tests/aws-emulator](../tests/aws-emulator) にあります。
本番ルートは実行せず、既存の AWS・Terraform 環境変数を除いた子プロセスで、
Emulator が生成した認証情報と一時的なローカル state を使用します。
provider は DynamoDB・SQS・STS の endpoint を明示し、アカウント ID `000000000000` に制限します。
既存シェルの設定や `~/.aws` は書き換えません。

調査対象を増やす場合は、この検証用構成にサービスの endpoint とテストを追加してください。
現在確認するのは STS と DynamoDB・SQS のライフサイクルです。全14環境を Emulator へ適用するタスクではありません。
Emulator は IAM ポリシー評価やアカウント間・リージョン間の動作を再現しないため、
既存の AWS 実環境の認証・権限問題の解消を確認する用途には使用できません。

既存の S3 バケットモジュールも調査しましたが、AWS provider 6.72 の S3 Control API は
endpoint のホストにアカウント ID を付けるため、`000000000000.127.0.0.1` の名前解決で失敗しました。
これは [公式 SDK 接続手順の S3 Control 制約](https://docs.aws.amazon.com/emulator/latest/userguide/point-sdk-to-emulator.html)と一致します。
TLS 検証を無効化する回避は採用せず、S3 モジュールの検証は既存のモックテストで継続します。

パッケージの版と SHA-256 は `tests/aws-emulator/packages.json`、ベースイメージは Dockerfile の digest で固定します。
更新時は [公式の版一覧と配布先](https://docs.aws.amazon.com/emulator/latest/userguide/versioning.html)から
両アーキテクチャの RPM と署名を取得し、[署名の検証手順](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-linux.html)
で公開鍵の fingerprint と署名を検証してから SHA-256 を記録します。
初回採用の両 RPM はこの手順で検証済みです。更新 PR では Linux CI とローカルの再検証結果を確認します。

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
