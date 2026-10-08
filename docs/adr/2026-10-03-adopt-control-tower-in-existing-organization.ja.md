# 既存 Organizations を維持して Control Tower を段階導入する

- 状態: 採用
- 作成日: 2026-10-03
- 決定日: 2026-10-03

## 背景

個人用 AWS 環境で Control Tower と IaC を学び、既存環境を整理したい。
既存コードには Management、Audit、Log Archive、Sandbox、Portfolio が定義されている。
過去の調査記録には既存 Landing Zone の存在とドリフトが記載されているが、現在の状態は再確認が必要である。

`terraform-aws` の GitHub 設定は `terraform-github` で管理している。
後者の state と Actions 認証は Portfolio の S3・OIDC・IAM ロールに依存しているため、
既存環境の一括撤去はリポジトリ管理の継続にも影響する。

## 決定

既存 Organizations と Management アカウントを維持する。
同じ組織内で新しい検証環境を構築する作業と、既存環境を段階的に撤去する作業を並行して進める。

- 既存 Landing Zone の修復・更新を第一候補とし、廃止・再構築は必要性と影響を確認して別途判断する。
- 検証用 OU・アカウントと新しい Terraform 構成を用意し、新旧のルートモジュールと state を分離する。
- 不要なアプリケーションは移行せず撤去し、必要なデータ・DNS・管理基盤は移行先を検証してから撤去する。
- `terraform-aws` は AWS 構成、`terraform-github` は GitHub 設定を担当する。
- Control Tower が生成・管理するリソースを Terraform で二重管理しない。
- AFT は初回検証に導入せず、アカウント払い出しの自動化が必要になった時点で検討する。
- AWS アカウントの閉鎖は、リソースの撤去とは別に判断する。

## 検討した代替案と採用理由

| 案 | 評価 |
| :--- | :--- |
| 既存組織を維持し、新規構築と段階撤去を並行する | 採用。学習を進めながら管理基盤を維持でき、不要なものだけを整理できる |
| 別の管理アカウント・Organizations で新設する | 初期構築を独立して試せるが、請求・認証・移行の管理が増えるため今回は採用しない |
| 既存環境を全撤去してから構築する | state・認証・DNS 等の依存関係を同時に失う可能性があり、学習開始にも全撤去の完了が必要になるため採用しない |
| 既存構成の修復だけを進める | 管理基盤の修復には必要だが、新しい IaC 構成を学ぶ目的には十分でないため全体方針にはしない |

## 結果と制約

新旧環境の並存期間には、両方の費用と管理が必要になる。
月額予算を決め、不要リソースを独立した単位で撤去する。

同一 Organizations の Landing Zone は 1 つであり、Landing Zone 自体を新旧並行構築する方針ではない。
既存 Landing Zone の更新による既存 OU・アカウントへの影響を確認する。
[既存組織への統制拡張](https://docs.aws.amazon.com/controltower/latest/userguide/about-extending-governance.html)

state・認証・復旧経路は依存する作業が終わるまで維持する。
個別リソースの削除対象、採用バージョン、詳細な移行手順は実環境の調査後に具体化する。
本 ADR の採用は、構築・移行・削除の完了を意味しない。

## 関連文書

- [Control Tower の段階導入と既存環境の撤去計画](../plans/2026-10-03-control-tower-adoption.ja.md)
- [第 1 段階の調査記録と保護対象](../investigations/2026-10-03-control-tower-phase1-inventory.ja.md)
- [ADR の管理](README.md)
