# 開発言語と検証方式の選定

## 要件

既存の AWS 構成を維持し、認証情報なしで変更を検証する。
macOS と Linux のローカル環境および CI で同じ検査を実行する。

## 候補

Terraform の構成と Python の回帰テスト、Node.js のルール生成を維持する方式と、
開発ツールを単一言語へ移行する方式を比較した。

## 選定理由

Terraform をインフラ定義、Python を回帰テスト、JavaScript を設定検査に使用する。
既存の検査を維持するため dev-standards の mise-project を採用する。
repo:build は配布物の生成ではなく全14環境の init・validate を実行する。
整形確認と rulesync の同期確認も共通の検証に含める。

## 検証範囲と制約

AWS の backend 接続、plan、apply は共通検証に含めない。
provider の取得にはネットワーク接続が必要となる。
Python 3、Git、mise はホスト側で用意する。
Bash スクリプトを使用するため検証対象 OS は macOS と Linux とし、Windows は未検証とする。
