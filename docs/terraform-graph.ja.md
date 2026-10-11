# Terraform の依存関係の可視化

[README](../README.md) / [Terraform の運用](terraform-operations.ja.md)

## GitHub Actions で生成する

GitHub Actions の `Terraform Graph` を手動実行し、対象環境を選択します。
各ルートの `terraform-graph-<環境名>-<ルート名>` artifact をダウンロードすると、
`dependency-graph.svg` をブラウザで表示できます。DOT ファイルも同梱し、保存期間は 7 日です。
ワークフローは `terraform/envs/<環境名>/*/terraform.tf` から対象を選びます。

Terraform 標準の簡略化されたグラフを Graphviz で SVG に変換します。
構成内のリソース・データソースの依存関係を示し、実際の AWS 構成や apply の差分は示しません。
Terraform 構成を一時コピーし、backend を空の local backend に置き換えるため、
AWS 認証や既存 state は不要です。元の構成・state・lockfile は変更しません。
lockfile は読み取り専用で扱います。デプロイ用ワークフローとは独立しています。

## ローカルで生成する

ローカル実行には、通常のセットアップに加えて Graphviz の `dot` コマンドが必要です。
macOS は `brew install graphviz`、Ubuntu は `sudo apt-get install graphviz`、
Windows は [Graphviz 公式配布](https://graphviz.org/download/)からインストールして PATH に追加します。
生成スクリプトは Python 3 で実行します。リポジトリのルートで実行してください。
Graphviz は任意の可視化用ツールのため、通常のセットアップには追加していません。
CI は Ubuntu のパッケージを使用するため、Graphviz の更新で SVG の配置が変わる場合があります。

```bash
mise exec -- python3 scripts/terraform-graph.py terraform/envs/portfolio/base_apne1 /tmp/terraform-graph
```

実装は [ワークフロー](../.github/workflows/terraform-graph.yml)と
[生成スクリプト](../scripts/terraform-graph.py)を参照してください。
