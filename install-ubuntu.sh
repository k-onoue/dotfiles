#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR
SERVER_MODE=false
CAN_USE_PRIVILEGES=false
PRUNE_VSCODE_EXTENSIONS=false
USE_SUDO=false

usage() {
  cat <<'EOF'
Usage: ./install-ubuntu.sh [--server] [--prune-vscode-extensions]

Options:
  --server                    Skip VS Code setup for CLI-only Ubuntu servers.
  --prune-vscode-extensions   Uninstall VS Code extensions not listed in dotfiles.
  -h, --help                  Show this help.
EOF
}

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_code_cli() {
  NODE_NO_WARNINGS=1 code "$@"
}

load_user_paths() {
  export PATH="$HOME/.local/bin:$HOME/.juliaup/bin:$PATH"
}

version_at_least() {
  local current="$1"
  local required="$2"
  local lowest

  lowest="$(printf '%s\n%s\n' "$required" "$current" | sort -V | head -n 1)"
  [ "$lowest" = "$required" ]
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
        ;;
      --server)
        SERVER_MODE=true
        ;;
      --prune-vscode-extensions)
        PRUNE_VSCODE_EXTENSIONS=true
        ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
    shift
  done

  if [ "$SERVER_MODE" = true ] && [ "$PRUNE_VSCODE_EXTENSIONS" = true ]; then
    printf 'The --prune-vscode-extensions option cannot be used with --server.\n' >&2
    exit 2
  fi
}

detect_privileges() {
  if [ "$(id -u)" -eq 0 ]; then
    CAN_USE_PRIVILEGES=true
    USE_SUDO=false
    log "Running as root; privileged package installation is available."
    return
  fi

  if ! command_exists sudo; then
    warn "sudo is not available; skipping privileged package installation."
    return
  fi

  if sudo -n -v >/dev/null 2>&1; then
    CAN_USE_PRIVILEGES=true
    USE_SUDO=true
    log "sudo is available; privileged package installation is enabled."
    return
  fi

  if [ -t 0 ] && sudo -v; then
    CAN_USE_PRIVILEGES=true
    USE_SUDO=true
    log "sudo is available; privileged package installation is enabled."
    return
  fi

  warn "sudo authentication failed, requires a terminal, or this user is not allowed to use sudo."
  warn "Skipping privileged package installation."
}

run_privileged() {
  if [ "$USE_SUDO" = true ]; then
    sudo "$@"
    return
  fi

  "$@"
}

install_apt_packages() {
  local packages=()
  local package

  if [ "$CAN_USE_PRIVILEGES" != true ]; then
    warn "Skipping apt package installation because privileged access is unavailable."
    return
  fi

  log "Updating apt package index."
  run_privileged apt-get update

  while IFS= read -r package || [ -n "$package" ]; do
    case "$package" in
      "" | \#*)
        continue
        ;;
    esac

    if ! apt-cache show "$package" >/dev/null 2>&1; then
      warn "apt package is not available in the configured repositories: $package"
      continue
    fi

    packages+=("$package")
  done < "$DOTFILES_DIR/packages.txt"

  if [ "${#packages[@]}" -eq 0 ]; then
    warn "No apt packages are available to install."
    return
  fi

  log "Installing apt packages."
  run_privileged apt-get install -y "${packages[@]}"
}

install_fzf() {
  local current_version=""
  local version_output
  local machine
  local target
  local latest_tag
  local version
  local archive_name
  local download_url
  local temp_dir

  if command_exists fzf; then
    version_output="$(fzf --version 2>/dev/null || true)"
    current_version="${version_output%% *}"
    if [ -n "$current_version" ] && version_at_least "$current_version" "0.53.0"; then
      log "fzf $current_version is already installed."
      return
    fi
    warn "fzf ${current_version:-unknown} is older than Yazi's recommended 0.53.0; installing a user-local fzf."
  fi

  if ! command_exists curl || ! command_exists tar || ! command_exists install; then
    warn "curl, tar, or install is missing; skipping user-local fzf installation."
    return
  fi

  machine="$(uname -m)"
  case "$machine" in
    x86_64 | amd64)
      target="linux_amd64"
      ;;
    aarch64 | arm64)
      target="linux_arm64"
      ;;
    armv7l)
      target="linux_armv7"
      ;;
    *)
      warn "Unsupported architecture for user-local fzf installation: $machine"
      return
      ;;
  esac

  latest_tag="$(
    curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest |
      sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' |
      head -n 1
  )" || latest_tag=""
  if [ -z "$latest_tag" ]; then
    warn "Could not determine the latest fzf release; skipping user-local fzf installation."
    return
  fi

  version="${latest_tag#v}"
  archive_name="fzf-${version}-${target}.tar.gz"
  download_url="https://github.com/junegunn/fzf/releases/download/${latest_tag}/${archive_name}"
  temp_dir="$(mktemp -d)"

  log "Installing fzf locally."
  if ! curl -fsSL "$download_url" -o "$temp_dir/$archive_name"; then
    rm -rf "$temp_dir"
    return 1
  fi
  tar -xzf "$temp_dir/$archive_name" -C "$temp_dir"
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$temp_dir/fzf" "$HOME/.local/bin/fzf"
  rm -rf "$temp_dir"
  export PATH="$HOME/.local/bin:$PATH"
}

install_bat() {
  local machine
  local target
  local version
  local archive_name
  local download_url
  local temp_dir

  if command_exists bat || command_exists batcat; then
    log "bat is already installed."
    return
  fi

  if ! command_exists curl || ! command_exists tar || ! command_exists install; then
    warn "curl, tar, or install is missing; skipping user-local bat installation."
    return
  fi

  machine="$(uname -m)"
  case "$machine" in
    x86_64 | amd64)
      target="x86_64-unknown-linux-gnu"
      ;;
    aarch64 | arm64)
      target="aarch64-unknown-linux-gnu"
      ;;
    armv7l)
      target="arm-unknown-linux-gnueabihf"
      ;;
    *)
      warn "Unsupported architecture for user-local bat installation: $machine"
      return
      ;;
  esac

  version="$(
    curl -fsSL https://api.github.com/repos/sharkdp/bat/releases/latest |
      sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' |
      head -n 1
  )"
  if [ -z "$version" ]; then
    warn "Could not determine the latest bat release; skipping user-local bat installation."
    return
  fi

  archive_name="bat-v${version}-${target}.tar.gz"
  download_url="https://github.com/sharkdp/bat/releases/download/v${version}/${archive_name}"
  temp_dir="$(mktemp -d)"

  log "Installing bat locally."
  if ! curl -fsSL "$download_url" -o "$temp_dir/$archive_name"; then
    rm -rf "$temp_dir"
    return 1
  fi
  tar -xzf "$temp_dir/$archive_name" -C "$temp_dir"
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$temp_dir/bat-v${version}-${target}/bat" "$HOME/.local/bin/bat"
  rm -rf "$temp_dir"
  export PATH="$HOME/.local/bin:$PATH"
}

install_zoxide() {
  local temp_installer

  if command_exists zoxide; then
    log "zoxide is already installed."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping zoxide installation."
    return
  fi

  log "Installing zoxide locally."
  temp_installer="$(mktemp)"
  if ! curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh -o "$temp_installer"; then
    rm -f "$temp_installer"
    return 1
  fi
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/man"
  if ! sh "$temp_installer" --bin-dir "$HOME/.local/bin" --man-dir "$HOME/.local/share/man"; then
    rm -f "$temp_installer"
    return 1
  fi
  rm -f "$temp_installer"
  export PATH="$HOME/.local/bin:$PATH"
}

install_github_cli() {
  local keyring_dir="/etc/apt/keyrings"
  local keyring_path="$keyring_dir/githubcli-archive-keyring.gpg"
  local list_path="/etc/apt/sources.list.d/github-cli.list"
  local temp_key
  local architecture

  if command_exists gh; then
    log "GitHub CLI is already installed."
    return
  fi

  if [ "$CAN_USE_PRIVILEGES" != true ]; then
    warn "GitHub CLI is not installed and privileged access is unavailable; skipping gh installation."
    return
  fi

  if ! command_exists wget || ! command_exists dpkg; then
    warn "wget or dpkg is missing; cannot add the GitHub CLI apt repository."
    warn "Install packages from packages.txt and rerun this script."
    return
  fi

  log "Installing GitHub CLI from the official apt repository."
  run_privileged install -d -m 0755 "$keyring_dir"

  temp_key="$(mktemp)"
  wget -nv -O "$temp_key" https://cli.github.com/packages/githubcli-archive-keyring.gpg
  run_privileged install -o root -g root -m 0644 "$temp_key" "$keyring_path"
  rm -f "$temp_key"

  architecture="$(dpkg --print-architecture)"
  printf 'deb [arch=%s signed-by=%s] https://cli.github.com/packages stable main\n' \
    "$architecture" "$keyring_path" | run_privileged tee "$list_path" >/dev/null

  run_privileged apt-get update
  run_privileged apt-get install -y gh
}

install_vscode() {
  local keyring_dir="/etc/apt/keyrings"
  local keyring_path="$keyring_dir/packages.microsoft.gpg"
  local list_path="/etc/apt/sources.list.d/vscode.list"
  local temp_key
  local architecture

  if [ "$SERVER_MODE" = true ]; then
    log "Server mode is enabled; skipping VS Code installation."
    return
  fi

  if command_exists code; then
    log "VS Code is already installed."
    return
  fi

  if [ "$CAN_USE_PRIVILEGES" != true ]; then
    warn "VS Code is not installed and privileged access is unavailable; skipping VS Code installation."
    return
  fi

  if ! command_exists wget || ! command_exists gpg; then
    warn "wget or gpg is missing; cannot add the VS Code apt repository."
    warn "Install packages from packages.txt and rerun this script."
    return
  fi

  log "Installing VS Code from the official Microsoft apt repository."
  run_privileged install -d -m 0755 "$keyring_dir"

  temp_key="$(mktemp)"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$temp_key"
  run_privileged install -o root -g root -m 0644 "$temp_key" "$keyring_path"
  rm -f "$temp_key"

  architecture="$(dpkg --print-architecture)"
  printf 'deb [arch=%s signed-by=%s] https://packages.microsoft.com/repos/code stable main\n' \
    "$architecture" "$keyring_path" | run_privileged tee "$list_path" >/dev/null

  run_privileged apt-get update
  run_privileged apt-get install -y code
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed."
    return
  fi

  if ! command_exists zsh; then
    warn "zsh is not installed; skipping Oh My Zsh installation."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping Oh My Zsh installation."
    return
  fi

  log "Installing Oh My Zsh."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_autosuggestions() {
  local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  local plugin_parent

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh is not installed; skipping zsh-autosuggestions installation."
    return
  fi

  if ! command_exists git; then
    warn "git is not available; skipping zsh-autosuggestions installation."
    return
  fi

  plugin_parent="$(dirname -- "$plugin_dir")"
  mkdir -p "$plugin_parent"

  if [ -d "$plugin_dir/.git" ]; then
    log "Updating zsh-autosuggestions."
    if ! git -C "$plugin_dir" pull --ff-only; then
      warn "Failed to update zsh-autosuggestions."
    fi
    return
  fi

  if [ -e "$plugin_dir" ]; then
    warn "zsh-autosuggestions path already exists and is not a git checkout: $plugin_dir"
    return
  fi

  log "Installing zsh-autosuggestions."
  if ! git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir"; then
    rm -rf "$plugin_dir"
    warn "Failed to install zsh-autosuggestions."
  fi
}

install_juliaup() {
  if command_exists juliaup; then
    log "juliaup is already installed."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping juliaup installation."
    return
  fi

  log "Installing juliaup."
  curl -fsSL https://install.julialang.org | sh -s -- -y
  export PATH="$HOME/.juliaup/bin:$PATH"
}

install_uv() {
  if command_exists uv; then
    log "uv is already installed."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping uv installation."
    return
  fi

  log "Installing uv."
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
  export PATH="$HOME/.local/bin:$PATH"
}

install_yazi() {
  if command_exists yazi; then
    log "Yazi is already installed."
    return
  fi

  if ! command_exists uv; then
    warn "uv is not installed; skipping Yazi installation."
    return
  fi

  log "Installing Yazi with uv."
  uv tool install yazi-bin
  export PATH="$HOME/.local/bin:$PATH"
}

install_uv_tool_if_missing() {
  local package="$1"
  local executable="$2"

  export PATH="$HOME/.local/bin:$PATH"

  if command_exists "$executable"; then
    log "$executable is already installed."
    return
  fi

  if ! command_exists uv; then
    warn "uv is not installed; skipping $package installation."
    return
  fi

  log "Installing $package with uv tool."
  if ! uv tool install "$package"; then
    warn "Failed to install $package with uv tool."
    return
  fi

  export PATH="$HOME/.local/bin:$PATH"
}

install_yazi_viewer_tools() {
  install_uv_tool_if_missing rich-cli rich
  install_uv_tool_if_missing nbpreview nbpreview
}

install_yazi_tokyo_night_flavor() {
  local flavor_dir="$HOME/.config/yazi/flavors/tokyo-night.yazi"
  local flavor_parent

  if ! command_exists git; then
    warn "git is not available; skipping Yazi Tokyo Night flavor installation."
    return
  fi

  flavor_parent="$(dirname -- "$flavor_dir")"
  mkdir -p "$flavor_parent"

  if [ -d "$flavor_dir/.git" ]; then
    log "Updating Yazi Tokyo Night flavor."
    if ! git -C "$flavor_dir" pull --ff-only; then
      warn "Failed to update Yazi Tokyo Night flavor."
    fi
    return
  fi

  if [ -e "$flavor_dir" ]; then
    warn "Yazi Tokyo Night flavor path already exists and is not a git checkout: $flavor_dir"
    return
  fi

  log "Installing Yazi Tokyo Night flavor."
  if ! git clone --depth 1 https://github.com/BennyOe/tokyo-night.yazi.git "$flavor_dir"; then
    rm -rf "$flavor_dir"
    warn "Failed to install Yazi Tokyo Night flavor."
  fi
}

install_yazi_piper_plugin() {
  local plugin_dir="$HOME/.config/yazi/plugins/piper.yazi"

  if ! command_exists ya; then
    warn "ya is not available; skipping Yazi piper plugin installation."
    return
  fi

  if [ -d "$plugin_dir" ] || ya pkg list 2>/dev/null | grep -Fq "piper"; then
    log "Yazi piper plugin is already installed."
    return
  fi

  log "Installing Yazi piper plugin."
  if ! ya pkg add yazi-rs/plugins:piper; then
    warn "Failed to install Yazi piper plugin."
  fi
}

install_herdr() {
  export PATH="$HOME/.local/bin:$PATH"

  if command_exists herdr; then
    log "Herdr is already installed."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping Herdr installation."
    return
  fi

  log "Installing Herdr locally."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://herdr.dev/install.sh | env HERDR_INSTALL_DIR="$HOME/.local/bin" sh
  export PATH="$HOME/.local/bin:$PATH"
}

install_nerd_font_symbols() {
  local font_dir="$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
  local existing_font
  local archive_path
  local temp_dir
  local font_file
  local font_count=0

  existing_font="$(find "$font_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -print -quit 2>/dev/null || true)"
  if [ -n "$existing_font" ]; then
    log "Symbols Nerd Font is already installed."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping Symbols Nerd Font installation."
    return
  fi

  if ! command_exists python3 && ! command_exists unzip; then
    warn "python3 or unzip is required to extract Nerd Font archives; skipping Symbols Nerd Font installation."
    return
  fi

  temp_dir="$(mktemp -d)"
  archive_path="$temp_dir/NerdFontsSymbolsOnly.zip"

  log "Installing Symbols Nerd Font locally."
  if ! curl -fsSL \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.zip \
    -o "$archive_path"; then
    rm -rf "$temp_dir"
    return 1
  fi

  mkdir -p "$temp_dir/fonts"
  if command_exists python3; then
    if ! python3 -m zipfile -e "$archive_path" "$temp_dir/fonts"; then
      rm -rf "$temp_dir"
      return 1
    fi
  elif ! unzip -q "$archive_path" -d "$temp_dir/fonts"; then
    rm -rf "$temp_dir"
    return 1
  fi

  mkdir -p "$font_dir"
  while IFS= read -r font_file; do
    install -m 0644 "$font_file" "$font_dir/"
    font_count=$((font_count + 1))
  done < <(find "$temp_dir/fonts" -type f \( -name '*.ttf' -o -name '*.otf' \))

  rm -rf "$temp_dir"

  if [ "$font_count" -eq 0 ]; then
    warn "No font files were found in the Symbols Nerd Font archive."
    return 1
  fi

  if command_exists fc-cache; then
    fc-cache -f "$font_dir" >/dev/null 2>&1 || warn "Failed to refresh fontconfig cache."
  fi
}

install_codex_cli() {
  local temp_installer

  if command_exists codex; then
    log "Codex CLI is already installed."
    return
  fi

  if [ "$CAN_USE_PRIVILEGES" != true ]; then
    warn "Codex CLI is not installed and privileged access is unavailable; skipping Codex CLI installation."
    return
  fi

  if ! command_exists curl; then
    warn "curl is not installed; skipping Codex CLI installation."
    return
  fi

  log "Installing Codex CLI."
  temp_installer="$(mktemp)"
  if ! curl -fsSL https://chatgpt.com/codex/install.sh -o "$temp_installer"; then
    rm -f "$temp_installer"
    return 1
  fi
  if ! CODEX_NON_INTERACTIVE=1 sh "$temp_installer"; then
    rm -f "$temp_installer"
    return 1
  fi
  rm -f "$temp_installer"
  export PATH="$HOME/.local/bin:$PATH"
}

check_codex_sandbox_dependencies() {
  local output

  if ! command_exists codex; then
    return
  fi

  if ! command_exists bwrap; then
    warn "Codex CLI is installed, but bubblewrap (bwrap) is not available."
    warn "Codex sandboxing with Linux namespaces may fail on this host."
    warn "Install the Ubuntu package 'bubblewrap' with apt, or ask the server administrator to install it."
    return
  fi

  if output="$(bwrap --unshare-user --ro-bind / / /usr/bin/true 2>&1)"; then
    log "bubblewrap can create a user namespace for Codex sandboxing."
    return
  fi

  warn "bubblewrap is installed, but it cannot create a user namespace."
  warn "Codex sandboxing with Linux namespaces may fail on this host."
  warn "bubblewrap test output: $output"
  warn "Ask the server administrator to enable unprivileged user namespaces or install/configure bubblewrap and uidmap."
}

check_managed_file_conflicts() {
  log "Checking for existing managed file conflicts."
  if [ "$SERVER_MODE" = true ]; then
    "$DOTFILES_DIR/bin/dotfiles-check-conflicts" --skip-vscode
    return
  fi

  "$DOTFILES_DIR/bin/dotfiles-check-conflicts"
}

stow_dotfiles() {
  log "Linking dotfiles with GNU Stow."

  if ! command_exists stow; then
    warn "GNU Stow is not installed; linking common dotfiles directly."
    link_stow_fallback_files
    return
  fi

  if ! stow --dir "$DOTFILES_DIR" --target "$HOME" --restow git zsh vim tmux; then
    warn "GNU Stow failed. Existing files may conflict with managed dotfiles."
    warn "Move conflicting files aside and run this script again."
    return 1
  fi
}

link_stow_fallback_files() {
  link_managed_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_managed_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
  link_managed_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
  link_managed_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
  link_managed_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

link_managed_file() {
  local source_path="$1"
  local target_path="$2"
  local target_dir
  local current_link

  target_dir="$(dirname -- "$target_path")"
  mkdir -p "$target_dir"

  current_link="$(readlink "$target_path" 2>/dev/null || true)"
  if [ "$current_link" = "$source_path" ]; then
    log "Already linked: $target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    warn "Skipping existing file: $target_path"
    warn "Move it aside and rerun this script to manage it from dotfiles."
    return
  fi

  ln -s "$source_path" "$target_path"
  log "Linked: $target_path"
}

link_vscode_files() {
  if [ "$SERVER_MODE" = true ]; then
    log "Server mode is enabled; skipping VS Code settings links."
    return
  fi

  link_managed_file \
    "$DOTFILES_DIR/vscode/settings.json" \
    "$HOME/.config/Code/User/settings.json"
  link_managed_file \
    "$DOTFILES_DIR/vscode/keybindings.json" \
    "$HOME/.config/Code/User/keybindings.json"
}

link_julia_files() {
  link_managed_file \
    "$DOTFILES_DIR/julia/startup.jl" \
    "$HOME/.julia/config/startup.jl"
}

link_yazi_files() {
  link_managed_file \
    "$DOTFILES_DIR/yazi/.config/yazi/theme.toml" \
    "$HOME/.config/yazi/theme.toml"
  link_managed_file \
    "$DOTFILES_DIR/yazi/.config/yazi/yazi.toml" \
    "$HOME/.config/yazi/yazi.toml"
}

link_herdr_files() {
  link_managed_file \
    "$DOTFILES_DIR/herdr/.config/herdr/config.toml" \
    "$HOME/.config/herdr/config.toml"
}

link_extra_files() {
  link_vscode_files
  link_julia_files
  link_herdr_files
  link_yazi_files
}

ensure_bash_integration() {
  local bashrc_path="$HOME/.bashrc"
  local integration_path="$DOTFILES_DIR/bash/.bashrc"
  local marker_start="# >>> dotfiles bash integration >>>"
  local marker_end="# <<< dotfiles bash integration <<<"

  if [ ! -r "$integration_path" ]; then
    warn "Bash integration is missing: $integration_path"
    return
  fi

  touch "$bashrc_path"

  if grep -Fq "$marker_start" "$bashrc_path"; then
    log "Bash integration is already configured."
    return
  fi

  log "Adding Bash integration to ~/.bashrc."
  {
    printf '\n%s\n' "$marker_start"
    printf 'if [ -r %q ]; then\n' "$integration_path"
    printf '  . %q\n' "$integration_path"
    printf 'fi\n'
    printf '%s\n' "$marker_end"
  } >> "$bashrc_path"
}

reload_zsh_config() {
  if ! command_exists zsh; then
    warn "zsh is not available; skipping ~/.zshrc reload."
    return
  fi

  if [ ! -r "$HOME/.zshrc" ]; then
    warn "$HOME/.zshrc is not readable; skipping zsh reload."
    return
  fi

  log "Sourcing ~/.zshrc in a new zsh process."
  if ! zsh -c 'source "$HOME/.zshrc"'; then
    warn "Failed to source ~/.zshrc. Check the zsh configuration."
    return 1
  fi

  if [ -t 1 ]; then
    warn "install.sh cannot reload the already-running parent shell."
    warn "Run 'source ~/.zshrc' or 'exec zsh -l' in this terminal to apply prompt changes immediately."
  fi
}

install_vscode_extensions() {
  local extensions_file="$DOTFILES_DIR/vscode/extensions.txt"
  local extension

  if [ "$SERVER_MODE" = true ]; then
    log "Server mode is enabled; skipping VS Code extensions."
    return
  fi

  if ! command_exists code; then
    warn "VS Code command 'code' is not available; skipping extension installation."
    return
  fi

  log "Installing VS Code extensions."
  while IFS= read -r extension || [ -n "$extension" ]; do
    case "$extension" in
      "" | \#*)
        continue
        ;;
    esac

    run_code_cli --install-extension "$extension" --force
  done < "$extensions_file"
}

write_vscode_extension_diff() {
  if [ "$SERVER_MODE" = true ]; then
    return
  fi

  if ! command_exists code; then
    return
  fi

  if [ "$PRUNE_VSCODE_EXTENSIONS" = true ]; then
    log "Writing unmanaged VS Code extension list."
    "$DOTFILES_DIR/bin/dotfiles-vscode-extension-diff" --prune
    return
  fi

  log "Writing unmanaged VS Code extension list."
  "$DOTFILES_DIR/bin/dotfiles-vscode-extension-diff"
}

main() {
  parse_args "$@"
  load_user_paths
  detect_privileges
  install_apt_packages
  install_fzf
  install_bat
  install_zoxide
  install_github_cli
  install_vscode
  install_oh_my_zsh
  install_zsh_autosuggestions
  install_juliaup
  install_uv
  install_yazi
  install_yazi_viewer_tools
  install_yazi_tokyo_night_flavor
  install_yazi_piper_plugin
  install_herdr
  install_nerd_font_symbols
  install_codex_cli
  check_codex_sandbox_dependencies
  install_vscode_extensions
  write_vscode_extension_diff
  check_managed_file_conflicts
  stow_dotfiles
  link_extra_files
  ensure_bash_integration
  reload_zsh_config

  log "Ubuntu setup complete."
}

main "$@"
