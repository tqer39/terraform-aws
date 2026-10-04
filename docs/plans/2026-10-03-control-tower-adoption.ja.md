# Control Tower の段階導入と既存環境の撤去計画

- 状態: 実施中
- 作成日: 2026-10-03
- 合意日: 2026-10-03
- 最終調査日: 2026-10-04

決定の背景・代替案・採用理由は [ADR](../adr/2026-10-03-adopt-control-tower-in-existing-organization.ja.md) に記録する。

## 合意した方針（2026-10-03）

個人用 AWS 環境として、学習を目的とする新規構築と、既存環境の段階的な撤去を並行して進める。
既存 Organizations と Management アカウントを維持し、同じ組織内に新しい検証環境を作る。
全リソースの削除やアカウント閉鎖を前提にしない。不要なアプリケーションは移行せず撤去する。

- 新規構築: 検証用 OU・アカウント、Terraform の新構成、state、CI/CD を整備する。
- 段階撤去: 不要な検証リソースから整理し、必要なデータと管理基盤は移行後に撤去する。
- Landing Zone: 既存の修復・更新を第一候補とする。廃止・再構築は必要性を確認した場合の別判断とする。
- リポジトリ: `terraform-aws` と `terraform-github` を継続利用し、責務を維持する。
- AFT: 初回の検証には導入せず、アカウント払い出しの自動化が必要になった時点で検討する。

## 現在地

第 1 段階の認証と読み取り専用の一次棚卸しを実施した。新設・修復・撤去は未実施である。
[公開用の調査記録](../investigations/2026-10-03-control-tower-phase1-inventory.ja.md)に進捗・判断基準・残課題を記録する。

- 再認証後、管理アカウントと組織内アカウントの実行主体を確認した。
- 組織・認証・主要サービス・state・費用を読み取り調査し、主要な保持対象を具体化した。
- 詳細な実環境情報は非公開のローカル記録に保持し、公開版には追加しない。
- 管理境界、保持要件、予算、撤去可否は確認を継続する。第 1 段階全体は未完了。
- CI の変更検出を修復し、AWS 実行の明示的な有効化と手動 apply の条件を追加する。
  実行再開前に既存構成と対象を確認し、今回の棚卸しでは workflow を起動しない。

## コードから確認できた既存構成

| アカウント | ID | 定義されている構成 |
| :--- | :--- | :--- |
| Management | `577523824419` | Organizations、OU、アカウント、SSO、DNS、OIDC、state バケット |
| Audit | `941697148827` | Organizations のアカウント定義 |
| Log Archive | `612023513349` | Organizations のアカウント定義 |
| Portfolio | `072693953877` | DNS、証明書、OIDC、デプロイ用 IAM ロール、state バケット |
| Sandbox | `107662415716` | 検証用 IAM ユーザー、OIDC、デプロイ用 IAM ロール、state バケット |

この一覧は実在リソースの棚卸しではない。他リポジトリ・手動構築のリソースも調査する。
`tqer39.dev` のホストゾーンは Management と Portfolio の両方に定義されている。
公開 apex の委任先は `rick.ns.cloudflare.com` と `roxy.ns.cloudflare.com`。
AWS の両ホストゾーンの用途、サブドメインの委任、証明書検証への依存、ドメイン登録の管理先は未確認。
公開 apex が Route 53 に委任されていないことだけでは、両ゾーンを削除可能と判断しない。

このリポジトリの Terraform は `1.8.1` 指定。過去の記録ではローカル CLI は `1.5.7`。
今回確認した `terraform-github` の対象ルートモジュールは `1.16.2` 指定。
既存 state の操作前に、state の記録と実行環境のバージョンを確認して整合させる。

## 計画時の API 調査記録（履歴）

<!-- cspell:ignore ZKDCJD -->

- Organizations の一覧は上記 5 アカウントで、すべて `ACTIVE`。
- SSO からは 5 アカウントすべてに `AdministratorAccess` ロールの割り当てが見える。
  個々のサービスへの実効権限は、SCP 等も含めて今後確認する。
- 管理アカウントの東京リージョンに Landing Zone `4A7TR6Z4ZKDCJD7N` が存在する。
- バージョンは `2.7`、状態は `ACTIVE`、ドリフト状態は `DRIFTED`。
- API が返す利用可能な最新バージョンは `4.0`。採用バージョンは未確定。
- 統制対象リージョンは `ap-northeast-1` のみ。
- セキュリティアカウントは Audit、集中ログアカウントは Log Archive。
- アクセス管理と集中ログが有効。Security OU と Sandbox OU が manifest に定義されている。

既存 Landing Zone のドリフト内容と更新の前提条件を調査する必要がある。
既存 Landing Zone の状態から、全 AWS リソースの状態や削除可否を推測しない。

## IaC の管理境界と保護対象

| 管理先 | 担当 |
| :--- | :--- |
| `terraform-github` | GitHub リポジトリ、Rulesets、Environments、Actions 設定 |
| `terraform-aws` | 独自 IAM、state 基盤、DNS、ワークロード、管理対象を明示した組織設定 |
| Control Tower | Landing Zone が生成するリソース、ベースライン、統制の適用 |

新構成は別ルートモジュール・別 state key に分離する。旧コードと state は撤去完了まで維持する。
同一リソースを新旧の state に重複登録しない。
既存リソースを移管する場合は、バックアップ後に state 移管または削除を伴わない管理解除・import を計画し、
移管元・移管先の plan で意図しない作成・削除・置換がないことを確認する。

特に以下は、依存する作業が完了するまで保護する。

- Portfolio の S3 バケット `terraform-tfstate-tqer39-072693953877-ap-northeast-1`。
  `terraform-github` の `terraform-aws` 設定は `terraform-github/repositories/terraform-aws.tfstate` を使用する。
  他リポジトリの state も同じバケットを利用しているため、対象 key だけで削除可否を判断しない。
- Portfolio の OIDC Provider と `portfolio-terraform-github-deploy` ロール。
  `terraform-github` の Actions が S3 backend にアクセスするために使用する。
- Portfolio の共通 IAM ポリシー `deploy-allow-specifics` と `deploy-deny-specifics`。
  上記ロールから参照され、別の `base_apne1` state が管理するため、ロールと一体で保護する。
- 各環境の Terraform state、暗号鍵、管理・復旧アクセス、SSO、必要な監査ログ。
- `tqer39.dev` の DNS、ドメイン登録、必要なデータとバックアップ。

`management/multi_account` は OU・アカウント所属・Organizations のサービス連携を管理している。
Control Tower が変更した値を Terraform が巻き戻さないよう、実環境と state を照合して所有者を決める。
特にコードでは Log Archive の所属が `WorkLoad` のため、実際の所属と Control Tower の設定を確認する。
Management の `base_apne1` には `removed { destroy = false }` があり、別の `base` が OIDC を定義する。
コードの有無だけで管理元を断定せず、両方の state と実リソースを照合する。

修復前の CI は文書だけの main push でも自動 apply へ進み得た。
本変更では変更検出を修復し、AWS 実行を `TERRAFORM_EXECUTION_ENABLED=true` による明示的な有効化の後に限定する。
apply はさらに main 上の手動実行で `CHECK_DIFF=_false` を指定した場合に限る。
今回の作業では変数の設定・workflow 起動・マージは行わず、AWS の実行再開は構成との整合確認後に判断する。

## 作業順序と完了条件

### 1. 現状確認と保護対象の確定

- [x] 個人用として、新規構築と段階撤去の方針を確定する。
- [x] 両リポジトリのコードから state・認証の依存関係を確認する。
- [x] 認証状態を確認し、失敗理由とコードに基づく保護対象・保護解除条件を調査記録へ残す。
- [x] 管理アカウントを操作できる認証を用意し、STS でアカウントと実行主体を確認する。
- [ ] Landing Zone、ドリフト、登録 OU・アカウント、SCP、委任管理者、SSO を再確認する。
- [ ] Terraform state、CloudFormation、サービス別 API を照合して棚卸しする。
  アカウント・リージョン・リソース ID・管理元・依存先・保持／移行／削除の判断を記録する。
  グローバルサービスも含め、取得エラーと未調査範囲を残す。タグ検索だけで「空」と判定しない。
- [ ] 利用料金を確認し、検証の月額予算と予算通知を決める。

第 1 段階では AWS リソースを変更しない。Terraform の init・plan・apply・state 書き換えは行わず、
S3 の一覧・取得 API で state の記録バージョンと管理対象のみを抽出する。state 本文は Git に保存しない。
SSO のロール名だけで権限を判断せず、各アカウントの STS とサービス別 API の成否を記録する。
未調査・取得エラー・結果が空の範囲を区別し、未確認リソースは保護を継続する。

完了条件: 新規構築に必要な基盤、独立して撤去できる対象、保護対象が区別できること。

### 2. 新規構築の準備

- [ ] 東京リージョンを第一候補として、ホームリージョン・統制対象リージョン・連携機能を確定する。
- [ ] 既存 Landing Zone の更新経路、採用バージョン、OU 更新による既存環境への影響を確認する。
- [ ] 新しい検証用 OU とアカウントの名称・メールアドレスを決める。
- [ ] 新しい Terraform ルートモジュールと state key、実行ロール、CI 対象を設計する。
  Terraform と provider のバージョンは採用機能に合わせて検証し、既存の更新とは分ける。
- [ ] bootstrap 用の認証と state 作成手順を定め、初回構築後に CI/CD へ引き継ぐ。
- [ ] state と復旧情報をアクセス制限した領域に退避する。認証情報・state は Git に追加しない。

完了条件: plan と更新手順で、保護対象の削除・置換や二重管理がないことを確認できること。

### 3. Control Tower と新環境の構築・検証

- [ ] 既存 Landing Zone を対応する手順で更新し、必要な OU・アカウント更新を実施する。
  更新で解決できず廃止・再構築が必要な場合は、影響と復旧手順を先に具体化する。
- [ ] 検証用 OU・アカウントを作成し、Control Tower の管理下に登録する。
- [ ] 新しい state・OIDC・実行ロール・CI/CD を構築し、小さな検証リソースをデプロイする。
- [ ] Landing Zone、OU、アカウントの状態、SSO ログイン、選択したログ連携の配送を確認する。
- [ ] 選択した統制が検証対象に適用され、必要な Terraform 操作が成功することを確認する。
- [ ] apply 後の plan、検証リソースの削除、利用料金を確認する。

完了条件: 新環境を CI/CD から再現可能に管理でき、統制・ログ・アクセスが正常であること。

### 4. 既存環境の段階撤去

この作業は、新規構築とは独立した単位で進める。
依存関係のない不要リソースは棚卸し後に先行撤去できるが、移行対象は移行先の検証後に撤去する。

- [ ] 対象ごとにリソース ID、依存関係、データ消失の影響、削除後の確認方法を記録する。
- [ ] 対象を再作成する自動 apply を停止・対象外化し、実行中ジョブがないことを確認する。
  新旧が同じワークフローを使う場合は、先に実行対象を分離する。
- [ ] 不要な検証リソース、不要なアプリケーション、移行済み基盤の順に削除 plan を確認して撤去する。
  Organizations、SSO、state バケット、Control Tower 管理リソースを一括 destroy に含めない。
- [ ] `terraform-github` の基盤を移行する場合、全利用 state の移行と Actions の動作を検証してから旧基盤を撤去する。
- [ ] サービス別 API と state を再照合し、削除待ち・残存理由・未確認範囲を記録する。
- [ ] 旧コードと CI 対象を整理する。空いたアカウントの再利用／閉鎖は別途判断する。

完了条件: 確定した削除対象が撤去され、GitHub 管理・DNS・新環境が動作し、不要な課金が残っていないこと。

## 次の作業

1. 非公開の調査記録を照合し、管理境界・保持要件・撤去可否を確定する。
2. Control Tower 更新の前提条件と影響を具体化する。
3. 新規アカウントの名称・メールアドレス、月額予算・通知先を決める。
4. CI 修復の検証を完了する。実行再開は state と構成の整合確認後に別途判断する。

現時点で削除可能と確定したリソースはない。第 1 段階を完了扱いにせず、全環境の削除を先に実行しない。

## Control Tower の公式仕様に基づく注意点

既存 Organizations に導入する場合は、既存の管理アカウントを使用できる。
既存 IAM Identity Center が `us-east-1` にある場合は、選択したホームリージョンにかかわらずそのインスタンスを使用する。
それ以外のリージョンにある場合は、Control Tower のホームリージョンを合わせる必要がある。
[IAM Identity Center のリージョン要件](https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-prereqs.html)
[既存組織への統制拡張](https://docs.aws.amazon.com/controltower/latest/userguide/about-extending-governance.html)

ホームリージョンは Landing Zone 設定後に変更できない。
共有アカウントの名称や役割は Landing Zone のバージョンに依存するため、採用バージョンで確認する。
[Landing Zone の設定事項](https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-configure.html)

既存 Landing Zone の廃止だけでは、組織、アカウント、Identity Center、ログバケット等は消えない。
既存 Control Tower が確認された場合は、残存リソースを別途計画に含める。
[廃止時に削除されないリソース](https://docs.aws.amazon.com/controltower/latest/userguide/resources-not-removed.html)

1 つの Organizations に作成できる Landing Zone は 1 つ。同一組織内で新旧 Landing Zone を並行構築しない。
新規構築と段階撤去を並行する対象は、主にワークロードとその IaC 構成とする。

現行の公式手順では、3.1 未満の Landing Zone は Reset を選べず、3.1 以上への Update が必要。
2.7 の記録を再確認し、更新先バージョン固有の前提条件を調べてから実行する。
[ドリフト修復とバージョン別の動作](https://docs.aws.amazon.com/controltower/latest/userguide/resolve-drift.html)

## Landing Zone 4.0 を選ぶ場合の更新前提（2026-10-04 確認）

採用版は未確定であり、この節は更新の実行承認や準備完了を示さない。
公式の移行手順に基づき、次の項目を非公開の実環境記録と照合してから更新手順を確定する。

- 既存版から 4.0 への更新と、Config / SecurityRoles 連携の無効化を同時に行わない。
  サービス連携用アカウントには同じ親 OU への所属要件がある。OU 移動を伴う場合は、
  SCP・Terraform の所属管理・既存統制への影響を先に確認する。
- API 更新では CloudTrail サービスロールのポリシー要件が変わる。
  読み取り確認後、必要な IAM 変更を更新手順に含めて別途レビューする。
- ドリフト通知は EventBridge に変わるため、通知先と受信確認を更新作業の対象にする。

根拠: [4.0 の主要変更](https://docs.aws.amazon.com/controltower/latest/userguide/key-changes-lz-v4.html)。

Config 連携を継続する場合、既存データの自動移動は行われず、新しい配送先が作成される。
Landing Zone 更新後は、対象 OU の再登録または ConfigBaseline の更新・有効化までを一連の作業として計画する。
その間に S3 配送が中断し得るため、記録保持期間内の履歴取得と配送再開の確認方法を用意する。
旧バケットの保持解除を更新成功だけで判断せず、旧データの参照・復旧要件を満たすまで残す。
根拠: [Config の移行動作](https://docs.aws.amazon.com/controltower/latest/userguide/config-updates-v4.html)。

新規検証アカウントの払い出しは、既存 Landing Zone・対象 OU・管理アクセス・ログ配送を検証した後に行う。
アカウント名・未使用メールアドレス・月額予算・保持期間が未確定の間は、作成 API を実行しない。
