# Control Tower 導入第 1 段階の棚卸しと保護対象

<!-- cspell:ignore charlestonroadregistry NOERROR -->

- 状態: 認証待ち（再ログイン必要、第 1 段階未完了）
- 調査日: 2026-10-03
- 対象計画: [Control Tower の段階導入と既存環境の撤去計画](../plans/2026-10-03-control-tower-adoption.ja.md)
- 方針: [既存 Organizations を維持して Control Tower を段階導入する ADR](../adr/2026-10-03-adopt-control-tower-in-existing-organization.ja.md)

## 調査の結論と証拠の範囲

管理アカウントの認証を確認できておらず、AWS 実環境の棚卸しは未完了である。
今回の記録では、ローカルの認証確認、公開 DNS の実測、コードから分かる依存関係、今後の保護方針を区別する。
コードに定義があることは、リソースや state が現在も実在することを意味しない。
過去の API 調査結果は今回の確認済み事実に含めない。

現時点で削除可能と確定したリソースはない。
state、認証、組織、DNS、監査・復旧基盤を優先して保護する方針を定め、
実際のリソース ID、管理元、依存先と解除条件の照合を認証復旧後に行う。
AWS のリソース変更、削除、アカウント閉鎖、Terraform の実行は行っていない。

コード調査の基準は、`terraform-aws` の PR #893 マージコミット `fb3aeaa` と、
`terraform-github` のコミット `2ff02f94079199c4e5a4a29c63c31fd94b4d5755` である。
後者へのリンクは、そのコミットのコードを指す。

## 認証の確認結果

| 対象 | 今回の確認結果 | 調査への影響 |
| :--- | :--- | :--- |
| `default` | 認証情報なし | STS で実行主体を確認できない |
| `portfolio` | SSO セッション期限切れ | Portfolio のサービス API と state を取得できない |
| 管理アカウント用 profile | 開始時は未設定。一時 profile `inventory-management` の STS は SSO セッションが期限切れまたは無効のため失敗 | Management `577523824419` の実行主体は未確認 |
| SSO device login | 利用者認証が未完了のまま `CreateToken` の `InvalidGrantException` で終了 | 再ログイン後に管理アカウントの認証を改めて確認する |

SSO login は 2026-10-03 18:50 JST の確認時に終了コード `254` で終了しており、
`Invalid device code provided` が返された。原因を期限切れとは断定しない。

一時 profile は既存の SSO 設定を使用し、アカウント `577523824419` と
ロール `AdministratorAccess` を指定した。
`aws sts get-caller-identity --profile inventory-management` は終了コード `255` で失敗した。
これは設定したアカウントやロールへのアクセス成功を示さない。永続的な `.aws/config` は変更していない。

認証完了後は `sts get-caller-identity` のアカウントと実行主体を確認してから調査する。
SSO ログインの成功だけで、管理アカウントや各メンバーアカウントへのアクセス成功とは判断しない。
調査に使用する API は読み取り操作に限定し、アカウントごとの取得可否とエラーを記録する。
アクセストークン、認証情報、device login のコード、Terraform state 本体は Git に保存しない。

再開時は `aws sso login --profile portfolio` で同じ SSO の認証を更新し、
管理アカウント用 profile のアカウント・ロール設定と STS の結果を確認する。
今回の一時 profile は永続設定ではないため、別のセッションでは再準備が必要になる。

## 読み取り専用調査の境界

以下は認証復旧後の調査方法であり、今回の AWS 実行結果ではない。

- Landing Zone の状態は `GetLandingZone`、OU・アカウントの baseline は
  `ListEnabledBaselines` の子要素を含む結果、統制は `ListEnabledControls` で確認する。
  `DRIFTED` だけで原因を特定せず、既存操作結果と CloudFormation の記録を照合する。
- SCP は root・祖先 OU・アカウントの付与を個別に確認する。
  [DescribeEffectivePolicy は SCP に対応しない](https://docs.aws.amazon.com/organizations/latest/APIReference/API_DescribeEffectivePolicy.html)。
- Terraform は実行せず、S3 の一覧・取得 API から state のバージョンと管理対象だけを要約する。
  CloudFormation の新しいドリフト検出は開始せず、既存の診断結果を読む。
- Resource Explorer の検索は初回利用時に index・view 等を自動作成し得るため利用しない。
  [公式の自動作成仕様](https://docs.aws.amazon.com/resource-explorer/latest/userguide/manage-immediate-resource-discovery-experience.html)
- 費用は既存 Cost Explorer の `GetCostAndUsage` で確認し、有効化や予算通知の作成は行わない。
  期間・通貨・費用指標・見積もり状態を記録する。更新遅延があり、API はページ取得ごとに課金される。
  [Cost Explorer の仕様](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html)

認証、リージョン、サービスごとの取得結果が揃うまでは、第 1 段階を完了としない。

## 公開 DNS の確認結果

2026-10-03 に、`dig` で `tqer39.dev` の公開 NS / SOA を読み取り確認した。
これは AWS 認証を用いない実測である。

| 確認内容 | 結果 |
| :--- | :--- |
| 公開 NS | `rick.ns.cloudflare.com.`、`roxy.ns.cloudflare.com.` |
| 公開 SOA | プライマリ NS は `rick.ns.cloudflare.com.`、管理連絡先フィールドは `dns.cloudflare.com.` |
| 親 `.dev` の権威サーバーへの非再帰問い合わせ | `ns-tld1.charlestonroadregistry.com` が `NOERROR` と上記 2 NS の委任を返した |
| `rick.ns.cloudflare.com` への非再帰問い合わせ | 権威応答を示す `aa` 付きで上記 2 NS を返した |

現在の公開 apex の委任先は Cloudflare である。
AWS に定義された同名 hosted zone が不要とは確定していない。
サブドメインの委任、ACM 検証レコード、他の利用者との依存関係を照合するまで両ゾーンを保護する。
NS の結果だけではドメイン登録先を特定できないため、registrar の管理先は引き続き未確認である。

## コードから確認した state の依存関係

### `terraform-aws` の 3 バケットと 13 ルートモジュール

以下は backend のコード定義であり、S3 上のオブジェクト一覧ではない。
全 13 ルートモジュールが Terraform `1.8.1`、AWS provider `5.46.0` を指定している。
backend のリージョンは `ap-northeast-1`、`encrypt = true` である。
実際の state に記録された Terraform バージョン、最終更新、リソース一覧は未取得である。

| 記号 | アカウント | backend バケット |
| :--- | :--- | :--- |
| M | Management `577523824419` | `terraform-tfstate-tqer39-577523824419-ap-northeast-1` |
| P | Portfolio `072693953877` | `terraform-tfstate-tqer39-072693953877-ap-northeast-1` |
| S | Sandbox `107662415716` | `terraform-tfstate-tqer39-107662415716-ap-northeast-1` |

| ルートモジュールと根拠 | バケット | backend key |
| :--- | :--- | :--- |
| [management/base](../../terraform/environments/management/base/terraform.tf) | M | `management/management-base.tfstate` |
| [management/base_apne1](../../terraform/environments/management/base_apne1/terraform.tf) | M | `terraform-aws/terraform/environments/management/management-base_apne1.tfstate` |
| [management/domains](../../terraform/environments/management/domains/terraform.tf) | M | `terraform-aws/terraform/environments/management/management-domains.tfstate` |
| [management/multi_account](../../terraform/environments/management/multi_account/terraform.tf) | M | `terraform-aws/terraform/environments/management/management-multi_account.tfstate` |
| [management/sso](../../terraform/environments/management/sso/terraform.tf) | M | `management/management-sso.tfstate` |
| [portfolio/base_apne1](../../terraform/environments/portfolio/base_apne1/terraform.tf) | P | `terraform-aws/terraform/environments/portfolio/portfolio-base_apne1.tfstate` |
| [portfolio/domains](../../terraform/environments/portfolio/domains/terraform.tf) | P | `terraform-aws/terraform/environments/portfolio/portfolio-domains.tfstate` |
| [portfolio/terraform_github](../../terraform/environments/portfolio/terraform_github/terraform.tf) | P | `terraform-aws/terraform/environments/portfolio/portfolio-terraform_github.tfstate` |
| [portfolio/terraform_vercel](../../terraform/environments/portfolio/terraform_vercel/terraform.tf) | P | `terraform-aws/terraform/environments/portfolio/portfolio-terraform_vercel.tfstate` |
| [portfolio/time_capsule](../../terraform/environments/portfolio/time_capsule/terraform.tf) | P | `terraform-aws/terraform/environments/portfolio/portfolio-time_capsule.tfstate` |
| [sandbox/base_apne1](../../terraform/environments/sandbox/base_apne1/terraform.tf) | S | `terraform-aws/terraform/environments/sandbox/sandbox-base_apne1.tfstate` |
| [sandbox/test-statement](../../terraform/environments/sandbox/test-statement/terraform.tf) | S | `terraform-aws/terraform/environments/sandbox/sandbox-test-statement.tfstate` |
| [sandbox/time_capsule](../../terraform/environments/sandbox/time_capsule/terraform.tf) | S | `terraform-aws/terraform/environments/sandbox/sandbox-time_capsule.tfstate` |

Management の `base` と `sso` は他のルートと key の接頭辞が異なる。
既知の接頭辞だけで S3 を検索せず、各バケットの全利用 key とオブジェクトのバージョンを調べる。

[state バケットのユースケース](../../terraform/usecases/terraform_tfstate_bucket/main.tf) は versioning を有効化する定義である。
[S3 モジュール](../../terraform/modules/s3/bucket/main.tf) の `force_destroy` は既定で `false` だが、
`prevent_destroy` は定義されていない。ユースケースに KMS キーの指定もない。
これらのコードから実際の暗号化方式、KMS キー、バケットポリシー、保持設定や復旧可能性を確定しない。

### `terraform-github` の 40 ルートモジュール

追跡対象の `terraform/src/repositories/*/terraform.tf` を確認した結果、
40 ルートモジュールが同一の Portfolio バケットを使用している。
backend key は 40 件で重複がなく、全て
`terraform-github/repositories/<リポジトリ名>.tfstate` と一対一で対応する。
対象ディレクトリに未追跡の `terraform.tf` はない。

全 40 ルートの Terraform 指定は `1.16.2` である。
`terraform-aws` リポジトリを管理するルートは
`terraform-github/repositories/terraform-aws.tfstate` を使用し、GitHub provider `6.12.1` を指定する。
根拠: [ルート一覧][github-roots]、[terraform-aws の backend][github-backend]。

S3 上の key 数が 40 件であることは未確認である。
削除済みのリポジトリ、別リポジトリ、手動作成の state や過去バージョンが存在する可能性を残す。
1 つの key の移行だけでは、このバケットの保護を解除しない。

[ワークフローの説明][github-workflow-doc] は S3 と DynamoDB ロックを記載するが、
40 backend 定義には `dynamodb_table` と `use_lockfile` の指定がない。
ロック基盤の有無と実際の運用は未確認として扱う。

## 保護方針と依存先

次の表は保護すべき機能とコード上の候補を定めるもので、実在リソースの確定一覧ではない。
解除条件を満たすまでは、削除・置換・一括 destroy の対象に含めない。
移行が不要な恒久的管理基盤は、引き続き保持する。

| 保護対象候補 | 依存先と理由 | 保護の解除・移行完了を判断する条件 |
| :--- | :--- | :--- |
| 既存 Organizations、Management、OU、アカウント | 組織・請求・Control Tower・SSO の基盤 | 維持する方針。所有者、OU 所属、サービス連携の照合前に変更しない。アカウント閉鎖は別判断 |
| 3 つの state バケット、全 key と必要な過去バージョン | `terraform-aws` 13 ルート、`terraform-github` 40 ルート、未確認の他利用者 | 全利用者と全 key を特定し、必要なバックアップ・移行・復旧確認と CI の参照先切り替えが完了すること |
| Portfolio の OIDC Provider、`portfolio-terraform-github-deploy` | GitHub リポジトリ管理の Actions が S3 backend にアクセスする | 全 GitHub 管理ルートの代替認証と backend を検証し、旧ロールへの依存がなくなること |
| Portfolio の `deploy-allow-specifics` / `deploy-deny-specifics` | 複数の deploy role が参照する共通 IAM ポリシー | 実際の全 attachment と利用者を調べ、参照移行または利用終了を確認すること |
| 各環境の OIDC・deploy role・管理／復旧アクセス・SSO | Terraform と管理者の継続アクセス | state 所有者と実際の利用者を特定し、代替経路での管理・復旧を検証すること |
| `tqer39.dev` の DNS、登録、ACM 検証レコード | 名前解決、証明書更新、他リポジトリのサービス | 権威 DNS・委任・登録先・全レコード利用者を確認し、必要な移行と名前解決・証明書更新を検証すること |
| Control Tower / CloudFormation の管理リソースと監査ログ | Landing Zone、統制、監査、障害時の調査 | 所有者と必要な保持期間を確定し、公式更新手順とログ配送・保持を検証すること |
| データ、バックアップ、暗号鍵 | 未棚卸しのアプリケーションや復旧経路 | データ所有者、復旧要否、暗号鍵の全利用先を確認し、必要な移行・復元検証を完了すること |

Portfolio の [base_apne1](../../terraform/environments/portfolio/base_apne1/main.tf) は、
state バケット、OIDC Provider、`portfolio-terraform-aws-deploy` と共通 IAM ポリシーの管理元として定義されている。
別ルートの [terraform_github](../../terraform/environments/portfolio/terraform_github/main.tf) が作る
`portfolio-terraform-github-deploy` は、[共通ポリシーを名前で参照する](../../terraform/usecases/deploy_role/terraform_github/main.tf)。
そのロールを [terraform-github の Actions][github-workflow] が使用するため、
state バケットだけを残して IAM を撤去することもできない。

Portfolio の [terraform_vercel](../../terraform/environments/portfolio/terraform_vercel/main.tf) と
[time_capsule](../../terraform/environments/portfolio/time_capsule/main.tf) にも他リポジトリ用 deploy role が定義される。
Sandbox の [test-statement](../../terraform/environments/sandbox/test-statement/main.tf) は検証用 IAM ユーザーを定義する。
これらは利用実績、アクセスキー、依存リソースを未確認のため、現時点では削除可能としない。

## 管理境界の未確定事項

| 論点 | コード上の事実 | 実環境・state との照合事項 |
| :--- | :--- | :--- |
| OU とアカウント所属 | [multi_account](../../terraform/environments/management/multi_account/main.tf) は Audit を Security、Log Archive と Portfolio を WorkLoad、Sandbox を Sandbox に置く | 実際の parent、Control Tower 登録状況、管理主体。特に Log Archive の所属 |
| Organizations のサービス連携 | [Organizations のユースケース](../../terraform/usecases/organizations/main.tf) が 7 サービスの明示リスト、SCP、ALL 機能を管理する | Control Tower 等が追加した連携を Terraform が戻さないか。API と state の差分と所有者 |
| Management の OIDC・IAM | [base_apne1](../../terraform/environments/management/base_apne1/main.tf) に OIDC・policy・role の `removed` / `destroy = false`、[base](../../terraform/environments/management/base/main.tf) に OIDC 定義がある | 管理解除・移管が実施済みか、どの state に残るか、deploy role の所有者 |
| SSO | [SSO モジュール](../../terraform/modules/sso/sso_account_assignment.tf) に全組織アカウントへの管理権限割り当てがある | instance、permission set、割り当てと実効権限、Control Tower と Terraform の管理境界 |
| DNS | [Management](../../terraform/environments/management/domains/main.tf) と [Portfolio](../../terraform/environments/portfolio/domains/main.tf) に同名ゾーン `tqer39.dev` がある | 公開 apex は Cloudflare への委任を確認済み。AWS 側の全レコード、サブドメイン委任、ドメイン登録先、ACM 利用先は未照合 |

Organizations のアカウント定義では `close_on_deletion` の既定は `false` だが、
これを OU 移動や管理解除の安全性の根拠にはしない。
DNS のコードは hosted zone と証明書検証を定義しており、ドメイン登録先の根拠にはならない。

## CI による AWS 更新の経路

文書だけを変更した PR でも、マージによる `main` への push は AWS 更新の起点になり得る。
[Management](../../.github/workflows/_terraform-aws-management.yml)、
[Portfolio](../../.github/workflows/_terraform-aws-portfolio.yml)、
[Sandbox](../../.github/workflows/_terraform-aws-sandbox.yml) の各 workflow は、
`workflow_call` に加えて `pull_request` と `push` / `main` を直接宣言しており、
`paths` / `paths-ignore` は設定していない。

[set-matrix](../../.github/actions/set-matrix/action.yml) は、PR では変更検出を行うが、
push では変更ファイルに関係なく deploy_pipeline の全対象を選ぶ。
対象は [Management 2 ルート](../../.github/workflows/deploy_pipeline/management)、
[Portfolio 5 ルート](../../.github/workflows/deploy_pipeline/portfolio)、
[Sandbox 2 ルート](../../.github/workflows/deploy_pipeline/sandbox) の計 9 ルートである。

認証・初期化・検証が成功し、plan が差分を返すと、push または手動実行のイベントでは
[terraform apply -auto-approve](../../.github/actions/terraform-apply/action.yml) に進む条件がある。
したがって、文書 PR のマージが必ず AWS を変更するわけではないが、読み取り専用であるとは保証できない。
PR イベントでは apply 条件が成立しない。別 workflow にある paths filter は、この経路を制限しない。

今回の読み取り専用調査は PR 作成までとし、マージによる自動適用は別途確認する。
AWS の実体・state・意図しない差分を確認するまでは、既存 workflow の手動実行も調査手段にしない。

## コードから確認した既存の実行上の問題

- [management/sso](../../terraform/environments/management/sso/main.tf) が参照する `../../../usecases/sso` は存在しない。
- [portfolio/base_apne1](../../terraform/environments/portfolio/base_apne1/main.tf) と
  [sandbox/base_apne1](../../terraform/environments/sandbox/base_apne1/main.tf) が参照する
  `../../../usecases/id_provider` は存在しない。
- `sso` と `id_provider` のモジュールは `terraform/modules/` にあるが、
  参照先の修正だけで state と整合するとは判断しない。
- CI の PR 変更検出には `terraform/src/` を渡すコードがあり、実際のルート配置 `terraform/environments/` と異なる。
  Terraform ファイルの変更が適切に検出されるかは別途修復・検証が必要である。
- Management の `multi_account` / `sso` / `domains` と Sandbox の `time_capsule` は
  現在の deploy_pipeline 一覧に含まれない。コードが存在しても自動適用対象とは限らない。

今回これらのコードは変更していない。既存構成がそのまま再実行可能であるとも確認していない。
棚卸しと管理境界の照合を行ってから、必要な修復を別の変更として扱う。

## 未調査範囲と第 1 段階の残作業

| 範囲 | 今回の取得状況 | 次に記録する内容 |
| :--- | :--- | :--- |
| Management の STS | 未確認 | アカウント ID、実行主体、認証時刻 |
| Organizations / Control Tower | 未取得 | 全アカウント、OU 所属、登録状況、Landing Zone、ドリフト、SCP、サービス連携、委任管理者 |
| IAM Identity Center / IAM | 未取得 | instance のリージョン、割り当て、管理・復旧経路、OIDC、role、policy と依存先 |
| 全アカウントのリージョン | 未取得 | 有効・無効リージョン、調査対象リージョン、各 API の取得可否 |
| Terraform state / S3 | 未取得 | 全 bucket / key、過去バージョン、暗号化、保護設定、state のメタデータとリソース所有者 |
| CloudFormation / StackSets | 未取得 | stack、管理先、リソース ID、状態、Control Tower との対応 |
| サービス別リソース | 未取得 | 全アカウント・全リージョンの資産、管理元、依存先、保持／移行／削除の判断 |
| グローバルサービス | 公開 DNS のみ実測済み、AWS API は未取得 | AWS hosted zone と公開 DNS の照合、ドメイン登録、CloudFront、IAM 等。タグ検索だけで空と判断しない |
| データ・監査ログ・バックアップ・KMS | 未取得 | 保存場所、保持期間、暗号鍵、復旧要件、ログ配送状況 |
| 費用・予算・通知 | 未取得・未決定 | 対象期間とアカウント別・サービス別費用、検証月額予算、通知先と設定方針 |

認証復旧後の結果には、確認日時、アカウント、リージョン、サービス、リソース ID、
管理元、依存先、保護または処分の判断、その根拠を付ける。
取得エラー、権限不足、API 非対応、未調査範囲は「リソースなし」と区別して残す。
機密情報を含む API の生出力や state 本体はアクセス制限された場所で扱い、文書には必要な要約だけを保存する。

第 1 段階の完了判定は、新規構築に必要な基盤、保護対象、独立して撤去できる対象を
実環境に基づいて区別できることとする。認証待ちの現在は、この条件を満たしていない。

[github-roots]: https://github.com/tqer39/terraform-github/tree/2ff02f94079199c4e5a4a29c63c31fd94b4d5755/terraform/src/repositories
[github-backend]: https://github.com/tqer39/terraform-github/blob/2ff02f94079199c4e5a4a29c63c31fd94b4d5755/terraform/src/repositories/terraform-aws/terraform.tf
[github-workflow]: https://github.com/tqer39/terraform-github/blob/2ff02f94079199c4e5a4a29c63c31fd94b4d5755/.github/workflows/terraform-github.yml
[github-workflow-doc]: https://github.com/tqer39/terraform-github/blob/2ff02f94079199c4e5a4a29c63c31fd94b4d5755/docs/workflow.md
