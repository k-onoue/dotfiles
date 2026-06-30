# dotfiles のセットアップ

このリポジトリは，macOS と Ubuntu に共通する開発環境の設定を管理する．
目的は，新しい Mac または Ubuntu PC で同じ開発環境を短時間で再現できる状態にすることだ．
OS 共通の dotfiles と，プロジェクトごとの依存関係を分けて管理する．

Python の依存関係は，各プロジェクトの `pyproject.toml` と `uv.lock` に置く．
Julia の依存関係は，各プロジェクトの `Project.toml` と `Manifest.toml` に置く．
このリポジトリでは，シェル，エディタ，ターミナル，パッケージマネージャの設定だけを扱う．

## 対応 OS

- macOS
- Ubuntu 22.04 以降

## 管理対象

このリポジトリでは，次の設定を管理する．

- Git の共通設定
- zsh と Oh My Zsh の設定
- vim の設定
- tmux の設定
- VS Code のユーザー設定，キーバインド，拡張機能一覧
- Julia の `startup.jl`
- macOS 用の `Brewfile`
- Ubuntu 用の `packages.txt`

Git の `user.name` と `user.email` は管理しない．
この二つは個人またはマシンに依存するため，必要な環境で個別に設定する．

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## 初回セットアップ

リポジトリを取得し，ルートディレクトリで `install.sh` を実行する．

```bash
git clone git@github.com:<your-account>/dotfiles.git ~/ws/dotfiles
cd ~/ws/dotfiles
./install.sh
```

Ubuntu の CLI 計算サーバでは，`--server` を付けて実行する．

```bash
cd ~/ws/dotfiles
./install.sh --server
```

`--server` は，VS Code 本体のインストール，VS Code 設定ファイルのリンク，VS Code 拡張機能のインストールをスキップする．
ローカル PC の VS Code から Remote SSH で接続する場合，サーバ側には VS Code 本体を入れない．

`install.sh` は OS を判定し，macOS では `install-mac.sh` を実行する．
Ubuntu では `/etc/os-release` を読んで Ubuntu であることを確認し，`install-ubuntu.sh` を実行する．
それ以外の OS では処理を停止する．

## macOS で実行される処理

`install-mac.sh` は次の処理を行う．

- Homebrew がなければインストールする
- `Brewfile` に書かれたパッケージを `brew bundle` でインストールする
- Oh My Zsh がなければインストールする
- GNU Stow で `git`，`zsh`，`vim`，`tmux` をホームディレクトリへリンクする
- VS Code の `settings.json` と `keybindings.json` をリンクする
- Julia の `startup.jl` をリンクする
- `vscode/extensions.txt` に書かれた VS Code 拡張機能をインストールする

VS Code の `code` コマンドが見つからない場合，拡張機能のインストールだけをスキップする．
その場合は VS Code で shell command を有効にしてから，`./install.sh` を再実行する．

## Ubuntu で実行される処理

`install-ubuntu.sh` は次の処理を行う．

- `apt-get update` を実行する
- `packages.txt` に書かれたパッケージをインストールする
- デスクトップ用途では，VS Code がなければ Microsoft の apt リポジトリを追加してインストールする
- Oh My Zsh がなければインストールする
- juliaup がなければインストールする
- uv がなければインストールする
- GNU Stow で `git`，`zsh`，`vim`，`tmux` をホームディレクトリへリンクする
- デスクトップ用途では，VS Code の `settings.json` と `keybindings.json` をリンクする
- Julia の `startup.jl` をリンクする
- デスクトップ用途では，`vscode/extensions.txt` に書かれた VS Code 拡張機能をインストールする

Ubuntu では `sudo` を使って apt の操作を行う．
sudo が使える場合は，初回実行時にパスワード入力が必要になる場合がある．
sudo が使えない場合は，apt によるパッケージインストールと VS Code 本体のインストールをスキップする．
その場合でも，Oh My Zsh，juliaup，uv のようにユーザー領域へ入るものは，必要なコマンドが揃っていれば処理を続ける．
GNU Stow がない場合は，Stow で管理するリンク作成もスキップする．

`--server` を付けた場合は，sudo の有無に関係なく VS Code まわりを処理しない．
このモードは，GUI を持たない Ubuntu 計算サーバを想定している．

## シンボリックリンク

GNU Stow は，このリポジトリ内のディレクトリをホームディレクトリへリンクする．
インストールスクリプトは次の対象を Stow で管理する．

```bash
stow --dir "$HOME/ws/dotfiles" --target "$HOME" --restow git zsh vim tmux
```

この結果，次のファイルがホームディレクトリにリンクされる．

- `git/.gitconfig` から `~/.gitconfig`
- `zsh/.zshrc` から `~/.zshrc`
- `zsh/.zprofile` から `~/.zprofile`
- `vim/.vimrc` から `~/.vimrc`
- `tmux/.tmux.conf` から `~/.tmux.conf`

既に同名の通常ファイルがある場合，Stow は衝突を検出して停止する．
既存の設定を確認し，必要なら退避してから再実行する．

VS Code と Julia の設定は OS ごとに配置先が異なるため，インストールスクリプトが個別にリンクする．
リンク先に既存ファイルがある場合，スクリプトはそのファイルを上書きせず，衝突として停止する．

## 既存環境への同期

既に VS Code や各種 CLI が入っている環境でも，同期の入口は同じである．

```bash
cd ~/ws/dotfiles
git pull
./install.sh
```

CLI 計算サーバでは，次のように実行する．

```bash
cd ~/ws/dotfiles
git pull
./install.sh --server
```

パッケージのインストール処理は，既に入っているものを再利用する．
Oh My Zsh，juliaup，uv も存在を確認してから処理する．
VS Code 拡張機能は，`vscode/extensions.txt` の内容を一つずつインストールする．
`--server` を付けた場合，VS Code 拡張機能もインストールしない．

sudo が使えない環境では，apt で入れるパッケージは管理者に依頼する．
既に必要なコマンドが入っていれば，dotfiles のリンクやユーザー領域のツール導入は続行できる．

設定ファイルの同期だけは，既存ファイルとの衝突に注意する．
このリポジトリは，既存の `~/.zshrc`，`~/.gitconfig`，VS Code の `settings.json` などを自動で上書きしない．
インストールスクリプトはリンク作成前に `bin/dotfiles-check-conflicts` を実行し，衝突がある場合は退避用のコマンド例を表示して停止する．

衝突だけを事前に確認するには，次を実行する．

```bash
cd ~/ws/dotfiles
./install.sh --check
```

CLI 計算サーバで VS Code 設定を確認対象から外すには，次を実行する．

```bash
cd ~/ws/dotfiles
./install.sh --server --check
```

このコマンドは `bin/dotfiles-check-conflicts` を呼び出すだけで，ファイルを変更しない．
衝突がある場合は，対象ファイルと退避用の `mv` コマンドを表示する．
表示されたファイルを確認し，必要な内容を dotfiles 側へ移してから退避する．

GNU Stow の挙動だけを確認したい場合は，dry run を使う．

```bash
cd ~/ws/dotfiles
stow --simulate --verbose --dir "$PWD" --target "$HOME" --restow git zsh vim tmux
```

## 更新方法

設定を変更したら，通常の Git ワークフローで記録する．

```bash
cd ~/ws/dotfiles
git status
git add .
git commit -m "Update development environment"
git push
```

別のマシンで変更を反映する場合は，`git pull` 後に `./install.sh` を再実行する．
インストールスクリプトは再実行できるようにしている．

## Brewfile の更新

macOS で現在の Homebrew パッケージ一覧を `Brewfile` に反映するには，次を実行する．

```bash
cd ~/ws/dotfiles
brew bundle dump --force --file Brewfile
```

このコマンドは，現在の Homebrew 環境をそのまま `Brewfile` に書き出す．
不要なパッケージが混ざる場合があるため，commit 前に差分を確認する．

## VS Code 拡張機能の更新

現在インストールされている VS Code 拡張機能を `vscode/extensions.txt` に書き出すには，次を実行する．

```bash
cd ~/ws/dotfiles
code --list-extensions > vscode/extensions.txt
```

新しい環境では，`./install.sh` が `vscode/extensions.txt` を読み，拡張機能を一つずつインストールする．

## uv の使い方

Python 自体と Python プロジェクトの依存関係は uv で管理する．
グローバルな `pip install` は行わない．

Python をインストールするには，次を実行する．

```bash
uv python install
```

プロジェクトの依存関係を同期するには，対象プロジェクトで次を実行する．

```bash
cd /path/to/project
uv sync
```

各 Python プロジェクトでは，`pyproject.toml` と `uv.lock` を commit する．
この二つのファイルが，プロジェクトごとの Python 環境を再現するための根拠になる．

## Julia の使い方

Julia は juliaup で管理する．
標準の安定版を使う場合は，次を実行する．

```bash
juliaup add release
juliaup default release
```

Julia プロジェクトでは，`Project.toml` と `Manifest.toml` を commit する．
新しい環境で依存関係を復元するには，対象プロジェクトで Julia を起動して次を実行する．

```julia
using Pkg
Pkg.instantiate()
```

## 今後追加しやすい構成

次のツールは今回のセットアップには含めない．
必要になった時点で，パッケージ一覧，設定ディレクトリ，インストール処理を追加する．

- starship
- lazygit
- direnv
- Docker
- Dev Containers
- Neovim
- Powerlevel10k
