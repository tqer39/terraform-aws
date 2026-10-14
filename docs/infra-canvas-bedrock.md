# Infra Canvas のローカル Bedrock 認証

Portfolio アカウント内の `infra-canvas-bedrock-local` を使います。
既存の `portfolio` プロファイルで SSO 認証し、専用ロールを引き受けます。
プロファイル名だけを変えて管理者権限を使う構成ではありません。
AWS アカウントと請求は Portfolio と共有します。別アカウントによる費用分離ではありません。

## 権限と反映

`terraform/envs/portfolio/infra_canvas_bedrock` でロールとインラインポリシーを管理します。
既存の base 環境とは Terraform のルート・state を分けます。
信頼する引受元は、Portfolio 内の既存 SSO `AdministratorAccess` ロールだけです。
許可する操作は `bedrock:InvokeModel`、モデルは Amazon Nova Lite です。
東京のモデル ARN と接続先リージョンに限定し、オンデマンドで直接呼び出します。
AWS のリソース作成・シークレット読み取り・モデル管理は許可しません。

反映は [デプロイフロー](deploy_flow/README.md)に従います。
PR のマージだけではロールは作成されません。
`main` の plan を確認し、承認後に GitHub Actions の手動 apply を実行します。
`TARGET_DIRECTORY=infra_canvas_bedrock` を選び、専用ロールとポリシーだけの差分であることを確認します。
初回は2件の作成、モデル切り替えではポリシーの変更が対象です。
`_all` を選ぶと他のルートも対象になるため、専用ルートを指定してください。

## ローカル設定

ロール作成後、既存の設定を保持して `~/.aws/config` に次のセクションを追加します。
既に同名のセクションがある場合は上書きせず、内容を確認します。

```ini
[profile infra-canvas]
role_arn = arn:aws:iam::072693953877:role/infra-canvas-bedrock-local
source_profile = portfolio
role_session_name = infra-canvas-local
region = ap-northeast-1
output = json
```

長期アクセスキーは発行・保存しません。SSO が期限切れなら再ログインします。

```bash
aws sso login --profile portfolio
aws sts get-caller-identity --profile infra-canvas
```

Infra Canvas の画面に次の設定を保存します。

| 項目 | 値 |
| :--- | :--- |
| AWS プロファイル | `infra-canvas` |
| AWS リージョン | `ap-northeast-1` |
| Bedrock モデル名 | `amazon.nova-lite-v1:0` |

コード抜粋・解析根拠を送信してよいことを確認してから生成します。
接続テストを1回実行した後、kazokubi のリポジトリ解析・DSL 生成を確認します。
構文エラーの自動修正は最大1回です。接続失敗時は生成を実行しません。
現在の図を上書きせず、生成候補で構文・参照・関係の根拠を検証します。

モデルの出典は [AWS の Nova Lite モデル仕様](https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-amazon-nova-lite.html)です。
モデル一覧・利用状態の確認だけでは実際の呼び出し成功は保証されません。接続テストで確認します。
利用モデルを変更する場合は、IAM ポリシーも変更・検証します。
