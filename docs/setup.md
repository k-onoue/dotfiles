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
- Herdr の設定
- VS Code のユーザー設定，キーバインド，拡張機能一覧
- VS Code Remote SSH 接続先へ自動インストールする拡張機能一覧
- Julia の `startup.jl`
- macOS 用の `Brewfile`
- Ubuntu 用の `packages.txt`
- Ubuntu の bash integration
- Yazi の Tokyo Night theme
- Yazi の preview，search，clipboard 用 optional dependencies
- Yazi の Markdown と Jupyter Notebook viewer
- iTerm2 の Tokyo Night Dynamic Profile

Git の `user.name` と `user.email` は管理しない．
この二つは個人またはマシンに依存するため，必要な環境で個別に設定する．
管理対象の `git/.gitconfig` は，存在する場合に `~/.gitconfig.local` も読み込む．
名前とメールアドレスは `~/.gitconfig.local` に置く．

```bash
git config --file ~/.gitconfig.local user.name "Your Name"
git config --file ~/.gitconfig.local user.email "you@example.com"
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
Remote SSH 接続先で使う拡張機能は，ローカル VS Code の `remote.SSH.defaultExtensions` で管理する．
ローカル側でこのリポジトリの VS Code 設定を同期しておけば，Remote SSH 接続時に VS Code Server 側へ必要な拡張機能が自動で入る．

`install.sh` は OS を判定し，macOS では `install-mac.sh` を実行する．
Ubuntu では `/etc/os-release` を読んで Ubuntu であることを確認し，`install-ubuntu.sh` を実行する．
それ以外の OS では処理を停止する．

## macOS で実行される処理

`install-mac.sh` は次の処理を行う．

- Homebrew がなければインストールする
- `Brewfile` に書かれたパッケージを `brew bundle` でインストールする
- GitHub CLI を Homebrew でインストールする
- Node.js と npm を Homebrew でインストールする
- Herdr を Homebrew でインストールする
- Yazi を Homebrew でインストールする
- Yazi の Tokyo Night flavor をインストールする
- Yazi の optional dependencies を Homebrew でインストールする
- Yazi の Markdown と Jupyter Notebook viewer をインストールする
- Yazi の `piper.yazi` plugin をインストールする
- Codex CLI を Homebrew cask でインストールする
- Oh My Zsh がなければインストールする
- zsh-autosuggestions がなければ Oh My Zsh の custom plugin としてインストールする
- GNU Stow で `git`，`zsh`，`vim`，`tmux` をホームディレクトリへリンクする
- VS Code の `settings.json` と `keybindings.json` をリンクする
- iTerm2 の Tokyo Night Dynamic Profile をリンクする
- Julia の `startup.jl` をリンクする
- Herdr の `config.toml` をリンクする
- Yazi の `theme.toml` をリンクする
- Yazi の `yazi.toml` をリンクする
- `vscode/extensions.txt` に書かれた VS Code 拡張機能をインストールする

VS Code の `code` コマンドが見つからない場合，拡張機能のインストールだけをスキップする．
その場合は VS Code で shell command を有効にしてから，`./install.sh` を再実行する．

## Ubuntu で実行される処理

`install-ubuntu.sh` は次の処理を行う．

- `apt-get update` を実行する
- `packages.txt` に書かれたパッケージをインストールする
- sudo が使える場合は，GitHub CLI を公式 apt リポジトリからインストールする
- デスクトップ用途では，VS Code がなければ Microsoft の apt リポジトリを追加してインストールする
- Oh My Zsh がなければインストールする
- zsh-autosuggestions がなければ Oh My Zsh の custom plugin としてインストールする
- juliaup がなければインストールする
- uv がなければインストールする
- Node.js と npm をインストールする
- Yazi を uv tool としてインストールする
- Yazi の Markdown と Jupyter Notebook viewer を uv tool としてインストールする
- Yazi の Tokyo Night flavor をインストールする
- Yazi の `piper.yazi` plugin をインストールする
- Yazi の optional dependencies を apt またはユーザー領域へインストールする
- Herdr をユーザー領域へインストールする
- sudo が使える場合は，Codex CLI を standalone installer でインストールする
- Codex CLI が入っている環境で `bubblewrap` が無い場合は warning を出す
- GNU Stow で `git`，`zsh`，`vim`，`tmux` をホームディレクトリへリンクする
- デスクトップ用途では，VS Code の `settings.json` と `keybindings.json` をリンクする
- Julia の `startup.jl` をリンクする
- Herdr の `config.toml` をリンクする
- Yazi の `theme.toml` をリンクする
- Yazi の `yazi.toml` をリンクする
- デスクトップ用途では，`vscode/extensions.txt` に書かれた VS Code 拡張機能をインストールする
- 既存の `~/.bashrc` に bash integration を読み込む marker block を追加する

Ubuntu では `sudo` を使って apt の操作を行う．
sudo が使える場合は，初回実行時にパスワード入力が必要になる場合がある．
sudo が使えない場合は，apt によるパッケージインストールと VS Code 本体のインストールをスキップする．
GitHub CLI も apt で入れるため，sudo が使えない場合はスキップする．
Codex CLI もこのリポジトリでは sudo が使える環境だけでインストールする．
Codex CLI の Linux sandbox は `bubblewrap` を使う場合があるため，`packages.txt` には `bubblewrap` と `uidmap` を含める．
sudo が使えないサーバで `bwrap` が無い場合，または `bwrap` が user namespace を作れない場合は，自動修復できないため管理者に `bubblewrap`，`uidmap`，unprivileged user namespace の設定確認を依頼する．
その場合でも，Oh My Zsh，juliaup，uv，Yazi，bat のようにユーザー領域へ入るものは，必要なコマンドが揃っていれば処理を続ける．
Yazi 用の `fzf`，`zoxide`，Symbols Nerd Font も，可能な範囲でユーザー領域へ入れる．
動画，PDF，SVG，画像，アーカイブ，Linux clipboard 用のコマンドは apt によって入れるため，sudo が使えない環境では既存のコマンドがなければスキップされる．
apt の設定済みリポジトリに無いパッケージも warning を出してスキップする．
GNU Stow がない場合は，`git`，`zsh`，`vim`，`tmux` の各ファイルを直接 symlink する．
ログインシェルが bash のサーバでも `y` wrapper と基本 alias を使えるように，`~/.bashrc` には `bash/.bashrc` を読み込む marker block を追記する．
Herdr は公式 installer で `~/.local/bin/herdr` へ入れるため，sudo が使えない環境でも導入できる．

`--server` を付けた場合は，sudo の有無に関係なく VS Code まわりを処理しない．
このモードは，GUI を持たない Ubuntu 計算サーバを想定している．

## Herdr for remote Codex work

Herdr は，Codex などの coding agent をリモートサーバ上で継続実行するための terminal multiplexer として使う．
このリポジトリでは，tmux は汎用 fallback として残し，Herdr を agent 作業用の第一候補にする．

macOS では，Homebrew で `herdr` を入れる．
Ubuntu では，公式 installer で `~/.local/bin/herdr` に入れる．
Herdr の設定は `herdr/.config/herdr/config.toml` で管理し，`~/.config/herdr/config.toml` へ個別にリンクする．

管理している Herdr 設定では，Tokyo Night theme を使い，first-run onboarding を無効にする．
新しい pane は元の pane または workspace の working directory を引き継ぐ．
Herdr の remote attach は，ユーザーの SSH 設定を読み込んだうえで接続を管理する．

リモートサーバで Codex 作業を続ける場合は，対象プロジェクトで Herdr を起動する．

```bash
ssh mini
cd ~/ws/project
herdr
codex
```

detach するには，Herdr 内で `ctrl+b` の後に `q` を押す．
SSH 接続や terminal window を閉じても，Herdr server と pane 内の process は残る．
再接続する場合は，同じサーバで `herdr` を起動する．

```bash
ssh mini
herdr
```

Codex integration は自動導入しない．
`herdr integration install codex` は `~/.codex/hooks.json` と `~/.codex/config.toml` を更新するため，必要性を確認してから手動で実行する．
Herdr は integration なしでも Codex pane を自動検出する．

## Yazi optional dependencies

Yazi の公式ドキュメントは，プレビューや検索を拡張する optional dependencies として次のコマンドを挙げている．
このリポジトリでは，macOS と Ubuntu で可能な範囲をインストール対象に含める．

- Nerd Font
- ffmpeg
- 7-Zip
- jq
- poppler
- fd
- ripgrep
- fzf
- zoxide
- resvg
- ImageMagick
- xclip，xsel，wl-clipboard

macOS では，Homebrew で `ffmpeg-full`，`sevenzip`，`poppler`，`zoxide`，`resvg`，`imagemagick-full`，`font-symbols-only-nerd-font` を入れる．
Yazi が新しい `ffmpeg` と `magick` を使えるように，`install-mac.sh` は `ffmpeg-full` と `imagemagick-full` を `brew link --force --overwrite` する．

Ubuntu では，apt で `ffmpeg`，`p7zip-full`，`poppler-utils`，`zoxide`，`resvg`，`imagemagick`，`xclip`，`xsel`，`wl-clipboard` を入れる．
設定済みリポジトリに無いパッケージはスキップする．
`fzf` は Yazi が 0.53.0 以上を要求するため，apt 版が古い場合は `~/.local/bin` に最新版を入れる．
`zoxide` が apt で入らない場合も，公式 install script で `~/.local/bin` に入れる．
Symbols Nerd Font は，GitHub Releases から `NerdFontsSymbolsOnly.zip` を取得し，`~/.local/share/fonts/NerdFontsSymbolsOnly` に展開する．

Ubuntu の `imagemagick` は OS のリリースによっては ImageMagick 7.1.1 未満の場合がある．
その場合，一部のフォント，HEIC，JPEG XL preview は Yazi 側で使えない可能性がある．

## Yazi Markdown and Notebook viewer

Markdown と Jupyter Notebook は，Yazi の `piper.yazi` plugin 経由で preview pane に表示する．
`yazi/.config/yazi/yazi.toml` は，`~/.config/yazi/yazi.toml` へ個別にリンクされる．
`~/.config/yazi` ディレクトリ全体は symlink しない．

Markdown viewer には `rich-cli` を使う．
Jupyter Notebook viewer には `nbpreview` を使う．
どちらも `uv tool install` でユーザー領域に入れるため，Ubuntu server でも uv が入っていれば sudo なしで導入できる．
Yazi 本体と同様に，`~/.local/bin` が PATH に入っている必要がある．

```bash
uv tool install rich-cli
uv tool install nbpreview
ya pkg add yazi-rs/plugins:piper
```

`install.sh` は上記を自動実行する．
既に `rich`，`nbpreview`，または `piper.yazi` が入っている場合は再利用する．
`.ipynb` の preview は notebook の内容をターミナル上に描画するものであり，Notebook kernel を起動してセルを実行するものではない．

## Tokyo Night theme

Yazi では，Tokyo Night flavor を `~/.config/yazi/flavors/tokyo-night.yazi` に clone する．
`yazi/.config/yazi/theme.toml` は，その flavor を使う設定だけを管理する．
このファイルはインストールスクリプトにより `~/.config/yazi/theme.toml` へリンクされる．
`yazi/.config/yazi/yazi.toml` は，Markdown と Jupyter Notebook viewer の設定を管理する．
`~/.config/yazi` ディレクトリ全体は symlink しない．
これは，`~/.config/yazi/flavors` に clone する flavor を dotfiles repo 内へ混入させないためである．

iTerm2 では，通常の設定全体を dotfiles から上書きしない．
代わりに Dynamic Profile として `iterm2/tokyo-night.plist` を管理し，macOS では `~/Library/Application Support/iTerm2/DynamicProfiles/tokyo-night.plist` へリンクする．
インストール後，iTerm2 の Profiles に `Tokyo Night` が追加される．
既存の iTerm2 profile は変更しないため，必要に応じて iTerm2 上で `Tokyo Night` profile を選ぶ．

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

VS Code，Julia，Herdr，Yazi，iTerm2 の追加設定は，インストールスクリプトが個別にリンクする．
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

複数の SSH 接続先をまとめて更新する場合は，ローカルの dotfiles から次を実行する．

```bash
cd ~/ws/dotfiles
bin/dotfiles-update-servers
```

デフォルトでは，`naist0`，`mini`，`mi1` に接続し，各サーバ上で `~/ws/dotfiles` に移動して `git pull --ff-only` と `./install.sh --server` を実行する．
対象ホストを明示する場合は，引数にホスト名を渡す．

```bash
bin/dotfiles-update-servers naist0
```

パッケージのインストール処理は，既に入っているものを再利用する．
Oh My Zsh，juliaup，uv も存在を確認してから処理する．
VS Code 拡張機能は，`vscode/extensions.txt` の内容を一つずつインストールする．
`--server` を付けた場合，VS Code 拡張機能もインストールしない．
ただし，Remote SSH 接続先で使う拡張機能は，サーバ上の `install.sh --server` ではなく，ローカル VS Code の `remote.SSH.defaultExtensions` が扱う．

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
ローカルにインストールされているが `vscode/extensions.txt` に無い拡張機能は，アンインストールしない．
インストールスクリプトは，その差分を `vscode/extensions.extra.txt` に書き出す．
このファイルはマシンごとの確認用であり，Git では管理しない．

差分だけを手動で更新するには，次を実行する．

```bash
cd ~/ws/dotfiles
bin/dotfiles-vscode-extension-diff
```

VS Code 拡張機能を `vscode/extensions.txt` に強制的に合わせるには，明示的に次を実行する．

```bash
cd ~/ws/dotfiles
./install.sh --prune-vscode-extensions
```

このオプションは，`vscode/extensions.txt` に無いローカル拡張機能をアンインストールする．
この処理は dotfiles のリンク衝突検査より前に実行される．
そのため，既存の `~/.zshrc` や VS Code 設定ファイルが衝突していても，拡張機能の強制同期だけは先に完了する．
削除を伴うため，通常の `./install.sh` では実行しない．
Ubuntu の `--server` とは併用できない．

## VS Code Remote SSH 拡張機能

Remote SSH 接続先に毎回必要になる拡張機能は，`vscode/settings.json` の `remote.SSH.defaultExtensions` で管理する．
この設定はローカル VS Code のユーザー設定として読み込まれ，SSH ホストへ接続したときに VS Code Server 側へ拡張機能をインストールする．
サーバ側に VS Code 本体を入れる必要はない．

`remote.SSH.defaultExtensions` には，リモートの workspace 側で動く拡張機能だけを入れる．
Python，Julia，Jupyter，formatter，linter，言語サポートが対象になる．
テーマ，Remote SSH 本体，ローカル UI だけで動く拡張機能は入れない．

新しく追加したい拡張機能がある場合は，ローカル VS Code にインストールしてから `vscode/extensions.txt` を更新し，必要なら `vscode/settings.json` の `remote.SSH.defaultExtensions` にも追加する．
既に接続中の SSH ホストへすぐ反映したい場合は，VS Code で Remote SSH の window を再読み込みするか，再接続する．

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
