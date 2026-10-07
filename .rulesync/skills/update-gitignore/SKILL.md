---
name: update-gitignore
description: .gitignore を更新するときに、Toptal の最新テンプレートを取得し、コードベースに必要な言語設定を追加して生成ブロックを更新する。
---

# .gitignore の更新

`.gitignore` を更新するときは、[Toptal の gitignore 生成サービス](https://www.toptal.com/developers/gitignore/) から最新の情報を取得する。

## テンプレートの選択と取得

1. 既存の生成ブロックの URL からテンプレート一覧を読み取る。次の例では `vim,linux,macos,windows,homebrew,intellij,terraform,visualstudiocode,node` を使用している。
2. コードベースのファイル拡張子と設定ファイルを確認する。既存の一覧を維持し、追加の言語や開発ツールがあれば、サービスで利用可能な関連テンプレートを追加する。たとえば `.py` があれば `python` を追加する。
3. 選択した一覧で `https://www.toptal.com/developers/gitignore/api/<テンプレート一覧>` にアクセスし、最新の生成結果を取得する。取得に失敗した場合は既存のブロックを保持し、取得できなかったことを報告する。

## 更新範囲

開始は、次の `Created by` と `Edit at` の連続した行で識別する。

```text
# Created by https://www.toptal.com/developers/gitignore/api/vim,linux,macos,windows,homebrew,intellij,terraform,visualstudiocode,node
# Edit at https://www.toptal.com/developers/gitignore?templates=vim,linux,macos,windows,homebrew,intellij,terraform,visualstudiocode,node
```

終了は、開始と同じテンプレート一覧の `End of` 行で識別する。

```text
# End of https://www.toptal.com/developers/gitignore/api/vim,linux,macos,windows,homebrew,intellij,terraform,visualstudiocode,node
```

- 開始と終了の間を取得した最新の生成内容で更新する。テンプレートを追加した場合は、上記3行の URL も新しい一覧にそろえる。
- 生成ブロックの外にある独自の除外設定やコメントは保持する。境界が欠けている、または更新対象が一意に特定できない場合は、ファイル全体を置換せず、その状態を報告する。
- 最終差分で更新範囲とテンプレート一覧を確認し、代表的な生成物が除外されることと、必要なソースファイルが新たに除外されていないことを `git check-ignore -v --no-index <対象パス>` で検証する。
