# 開発依存の脆弱性修正

確認日: 2026-10-09

## 修正対象

Dependabot の未解決アラート 14 件を調査し、開発用の npm 依存を更新した。
Handlebars 4.7.10、simple-git 4.0.2、markdown-it 14.3.2 以降、
flatted 3.4.4、glob 10.5.0、smol-toml 1.9.0 を lockfile で確認した。
Renovate の更新は Critical 修正を含むため、通常の公開後 7 日待機の例外とする。
インストールには `--ignore-scripts` を使用する。

## 限定した override

markdownlint-cli が古い範囲に固定している js-yaml を 5.4.3、
smol-toml を 1.9.0 に更新した。
micromark-extension-math が使う KaTeX を 0.18.2 に更新した。
上流の制約を越えるため、YAML・TOML 設定の読み込み、数式を含む Markdown の検証と
違反検出を回帰テストで確認する。上流が修正版を採用したら override を解除する。

## 残る制約

更新後の `npm audit` は Critical 0 件、High 9 件、Moderate 6 件である。
15 件は以下の 2 種類の脆弱性と、それを使う依存パッケージへの波及を数えている。
すべて開発依存であり、脆弱性ゼロを達成したという意味ではない。

- [braces の深いパターンによるスタック枯渇](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm):
  3.0.3 以下が対象で、確認時点に修正版がない。Renovate・rulesync の依存に残る。
- [sprintf-js の精度指定による処理停止](https://github.com/advisories/GHSA-hp3w-g68c-fv3c):
  1.1.3 以下が対象で、確認時点に修正版がない。
  Renovate のログ処理、rulesync の YAML パーサーの依存に残る。

PR の CI は読み取り権限で実行し、AWS 認証や apply と分離している。
それでも悪意ある入力による CI 停止の可能性は残るため、アラートを解決扱いにしない。
上流修正版への更新か、影響する依存の置き換えを別途検証する必要がある。
