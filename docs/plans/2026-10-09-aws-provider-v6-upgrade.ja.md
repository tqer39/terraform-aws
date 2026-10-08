# AWS provider v6 への移行計画

状態: 実施中
作成日: 2026-10-09
合意日: 2026-10-09（依存更新を安全に消化する依頼に基づく）

## 目的と対象

全13環境の AWS provider を v5 最終版から 6.67.0 に更新する。
provider の固定バージョンと公式署名付き lockfile を変更し、
リソース、backend、権限、state の構成変更はこの PR に含めない。
ローカルの apply、destroy、state 操作は行わない。

## 判断

[公式 v6 移行ガイド](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade)
は、v5 最終版で plan に想定外の変更や移行対象の非推奨警告がないことの確認を要求する。
構文検証のみでは既存 state との互換性を確認できないため、
v5 と v6 の実環境 plan を確認するまで v6 の PR は draft に留める。

リージョン引数の追加による state 差分、S3 の `bucket_region`、
Identity Store の削除された `filter`、GuardDuty の非推奨 `datasources` を確認対象とする。
既存環境が参照していない GuardDuty モジュールを、この依存更新で移行したとは扱わない。
有効化する場合は `aws_guardduty_detector_feature` への移行を別途検証する。

## 作業順と完了条件

- [x] AWS 5.100.0 への更新を #926 でマージする。
- [ ] management・portfolio・sandbox の認証を用意し、v5 で全13環境の plan を確認する。
- [x] v6 の公開日時と署名を確認し、4プラットフォームの lockfile を生成する。
- [x] 全13環境の fmt・backend 無効の init・validate とローカル lint・回帰テストを通す。
- [ ] PR の全 CI を通し、レビュー指摘を解消する。
- [ ] v6 で全13環境の plan を確認し、意図しない削除・再作成・権限変更がないことを確認する。
- [ ] 上記の証跡を PR に記録し、draft を解除してマージする。

plan は `-lock=false -input=false` で state への書き込みを避ける。
plan とログには機密値が含まれ得るため、公開 PR には件数と判断結果のみを記録する。
認証情報、state、plan ファイルをコミットしない。

## 現在の制約

確認時点では default プロファイルに認証がなく、portfolio の SSO セッションは期限切れである。
実環境 plan は未実施であり、利用できるプロファイルについて回答を待っている。
