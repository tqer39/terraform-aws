# GitHub Actions のサプライチェーン対策

外部 Action は完全なコミット SHA、コンテナは SHA256 ダイジェストに固定します。
更新は Renovate の PR を手動レビューします。
公開から 7 日の待機や更新の自動固定は、別の [Renovate 対策 PR](https://github.com/tqer39/terraform-aws/pull/905) で扱います。
固定値の更新時は、上流リポジトリのタグとコミットの対応、内部の Action やダウンロードも確認してください。

## 実行権限と信頼境界

- 全ワークフローの既定権限は `contents: read` です。必要なジョブだけ権限を追加します。
- checkout の `persist-credentials` は `false` にして Git にトークンを残しません。
- PR は Terraform の初期化を `-backend=false -lockfile=readonly` で実行し、静的検証を行います。
  AWS 認証と Slack のシークレットは渡しません。
- AWS 認証を使う Terraform ジョブは `main` の push、schedule、workflow_dispatch に限定します。
  `TERRAFORM_EXECUTION_ENABLED=true` が必要です。apply は既存どおり、明示的な手動操作と差分を条件にします。
- Terraform AWS 用の IAM ロールは OIDC の subject をこのリポジトリの `main`、
  audience を `sts.amazonaws.com` に限定します。PR がワークフローを書き換えても AWS 側で拒否するためです。
  この防御は信頼ポリシーを AWS に反映してから有効になります。
- 定期差分チェックの呼び出し元は、再利用ワークフローに必要な OIDC と deployments 権限をジョブ単位で渡します。
- Secrets Manager のテストは `main` の手動実行に限定し、シークレットの値をログに出しません。
- ライセンス更新用の GitHub App トークンは、このリポジトリの contents と pull requests の書き込みに限定します。
  実行対象は `main` です。

## PR での生成処理

Terraform のドキュメント生成と Renovate のプラットフォーム用チェックサム確認は読み取り専用です。
PR のコードから書き込みトークンを取得できないよう、自動 commit と push は行いません。
生成結果に差分があれば CI が失敗します。差分をローカルで生成し、レビュー対象の PR に含めてください。

ドキュメントは `terraform/modules/` の各モジュールで、次のコマンドで生成します。
CI の固定コンテナに含まれる terraform-docs と同じバージョンを使用してください。

```bash
terraform-docs markdown table --hide-empty --indent 2 --output-file USAGE.md --output-mode inject .
```

チェックサムは対象の Terraform ルートで、provider の選択バージョンを変更せずに追加します。

```bash
terraform init -backend=false -input=false -lockfile=readonly
terraform providers lock -platform=darwin_amd64 -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64
```

## 検証と残る範囲

`mise run lint` の pinact は外部 Action の SHA 固定を、Python の回帰テストはコンテナの固定、
PR と AWS 実行の分離、シェル入力の扱いを検証します。
Node.js の依存は lockfile から `npm ci --ignore-scripts` でインストールします。
mise と TFLint はバージョンと実行ファイルのチェックサムを固定します。
PR の plan コメントを廃止したため、投稿用の tfcmt は実行しません。
認証を使うジョブでは TFLint の共有プラグインキャッシュを使用しません。

固定は上流の参照先の差し替えを防ぎますが、選択したコード自体の安全性を保証しません。
セットアップスクリプトが取得する Homebrew などの依存、ホストイメージ、外部 provider は別途レビューが必要です。
AWS の IAM 信頼ポリシー、GitHub のブランチ保護、レビュー必須設定は実環境でも確認してください。
management のデプロイロールは現在のルート構成で無効化されており、Secrets Manager 用のロール定義もこのリポジトリでは確認できません。
これらの既存ロールにも subject と audience の制限を別途反映する必要があります。
portfolio と sandbox のルート全体の validate は、既存の `aws_iam_role_policy_attachments_exclusive` が
固定中の AWS provider 5.46.0 に未対応のため失敗します。信頼ポリシー単体の validate は成功しています。
信頼ポリシーを反映する前に、この既存の互換性問題も解消してください。
特に `.github/` の変更にはレビューを要求し、GitHub 側で Action の SHA 固定を必須にする設定も推奨します。

根拠は [GitHub の安全な利用のリファレンス](https://docs.github.com/en/actions/reference/security/secure-use) を参照してください。
