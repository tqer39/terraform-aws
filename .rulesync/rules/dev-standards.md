---
root: false
targets: ["*"]
description: dev-standards の共通開発ルールの入口
globs: ["**/*"]
---

# 共通開発ルール

作業開始時に `.standards/rules.md` と言語選定記録を読む。
生成物は直接編集せず、正本から再適用する。
作業終了前に `mise run standards:verify` を実行し、未実行の検査を成功と報告しない。
