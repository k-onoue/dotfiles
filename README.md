# dotfiles

macOS と Ubuntu で共通して使う開発環境設定を Git で管理するためのリポジトリです。

OS 共通の設定はこのリポジトリに置き、Python や Julia のプロジェクト依存関係は各プロジェクトの `pyproject.toml` / `uv.lock`、`Project.toml` / `Manifest.toml` に分離します。

## 対応 OS

- macOS
- Ubuntu 22.04 以降

## 初回セットアップ

リポジトリを取得して、ルートディレクトリで `install.sh` を実行します。

```bash
git clone git@github.com:<your-account>/dotfiles.git ~/ws/dotfiles
cd ~/ws/dotfiles
./install.sh
```

`install.sh` は OS を判定し、macOS では `install-mac.sh`、Ubuntu では `install-ubuntu.sh` を呼び出します。

主な処理は次の通りです。

- パッケージマネージャによる基本ツールのインストール
- Oh My Zsh のインストール
- GNU Stow による dotfiles のシンボリックリンク作成
- VS Code 拡張機能のインストール
- Julia / VS Code 設定ファイルのリンク作成

既に `~/.zshrc` や `~/.gitconfig` などが存在する場合、GNU Stow は衝突を検出して停止します。既存ファイルを確認し、必要であれば退避してから再実行してください。

## 更新方法

設定を変更したら通常の Git ワークフローで管理します。

```bash
cd ~/ws/dotfiles
git status
git add .
git commit -m "Update development environment"
git push
```

別のマシンで反映する場合は `git pull` 後に `./install.sh` を再実行します。各インストールスクリプトは再実行できるように作っています。

## Brewfile 更新方法

macOS で Homebrew の状態をこのリポジトリへ反映するには次を実行します。

```bash
cd ~/ws/dotfiles
brew bundle dump --force --file Brewfile
```

不要なパッケージが混ざった場合は `Brewfile` を手で整理してから commit します。

## VS Code 拡張更新方法

現在インストール済みの VS Code 拡張を `extensions.txt` に書き出します。

```bash
cd ~/ws/dotfiles
code --list-extensions > vscode/extensions.txt
```

新しいマシンでは `./install.sh` 実行時に `vscode/extensions.txt` の内容がインストールされます。

## uv の使い方

Python 自体とプロジェクト依存関係は uv で管理します。グローバルな `pip install` は行いません。

Python をインストールする例:

```bash
uv python install
```

プロジェクトで依存関係を同期する例:

```bash
cd /path/to/project
uv sync
```

プロジェクトごとに `pyproject.toml` と `uv.lock` を commit し、環境の再現性を保ちます。

## Julia の使い方

Julia は juliaup で管理します。

```bash
juliaup add release
juliaup default release
```

Julia プロジェクトでは `Project.toml` と `Manifest.toml` を commit します。新しい環境で依存関係を復元するには Julia REPL で次を実行します。

```julia
using Pkg
Pkg.instantiate()
```

## シンボリックリンク

GNU Stow で次のパッケージをホームディレクトリへリンクします。

```bash
stow git
stow zsh
stow vim
stow tmux
```

インストールスクリプトでは次のように実行します。

```bash
stow --dir "$HOME/ws/dotfiles" --target "$HOME" --restow git zsh vim tmux
```

VS Code と Julia の設定は OS ごとに配置先が異なるため、インストールスクリプト内で個別にリンクします。

## 今後追加しやすいもの

次のツールは今回導入しませんが、必要になったときに `Brewfile` / `packages.txt` / 設定ディレクトリを追加しやすい構成にしています。

- starship
- lazygit
- direnv
- Docker
- Dev Containers
- Neovim
- Powerlevel10k
