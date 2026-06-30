---
name: documentation-layout
description: README.md と docs/ の分担を定める．README.md は見出しだけに保ち，説明，手順，設計方針，今後追加する文書は docs/ 配下で管理する．
---

# ドキュメント配置規範

このリポジトリで README.md または docs/ 配下の文書を作成・編集するときは，この規範に従う．

## README

README.md は，次の一行だけにする．

```markdown
# dotfiles
```

README.md には，概要，セットアップ手順，運用説明，リンク集を置かない．
説明を追加したい場合は，docs/ 配下の文書を作成または更新する．

## docs

説明，手順，設計方針，運用規則は docs/ 配下に置く．
将来追加する新しいドキュメントも docs/ 配下で管理する．

文書は内容ごとに分け，内容が分かるファイル名を付ける．
たとえば，セットアップ手順は `docs/setup.md` に置く．

日本語の本文を書くときは，`INSTRUCTIONS/japanese-tech-writing.md` の文章規範にも従う．
