#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_apt_packages() {
  local packages=()
  local package

  log "Updating apt package index."
  sudo apt-get update

  while IFS= read -r package || [ -n "$package" ]; do
    case "$package" in
      "" | \#*)
        continue
        ;;
    esac
    packages+=("$package")
  done < "$DOTFILES_DIR/packages.txt"

  log "Installing apt packages."
  sudo apt-get install -y "${packages[@]}"
}

install_vscode() {
  local keyring_dir="/etc/apt/keyrings"
  local keyring_path="$keyring_dir/packages.microsoft.gpg"
  local list_path="/etc/apt/sources.list.d/vscode.list"
  local temp_key
  local architecture

  if command_exists code; then
    log "VS Code is already installed."
    return
  fi

  log "Installing VS Code from the official Microsoft apt repository."
  sudo install -d -m 0755 "$keyring_dir"

  temp_key="$(mktemp)"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$temp_key"
  sudo install -o root -g root -m 0644 "$temp_key" "$keyring_path"
  rm -f "$temp_key"

  architecture="$(dpkg --print-architecture)"
  printf 'deb [arch=%s signed-by=%s] https://packages.microsoft.com/repos/code stable main\n' \
    "$architecture" "$keyring_path" | sudo tee "$list_path" >/dev/null

  sudo apt-get update
  sudo apt-get install -y code
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed."
    return
  fi

  log "Installing Oh My Zsh."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_juliaup() {
  if command_exists juliaup; then
    log "juliaup is already installed."
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

  log "Installing uv."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

stow_dotfiles() {
  log "Linking dotfiles with GNU Stow."

  if ! stow --dir "$DOTFILES_DIR" --target "$HOME" --restow git zsh vim tmux; then
    warn "GNU Stow failed. Existing files may conflict with managed dotfiles."
    warn "Move conflicting files aside and run this script again."
    return 1
  fi
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

link_extra_files() {
  link_managed_file \
    "$DOTFILES_DIR/vscode/settings.json" \
    "$HOME/.config/Code/User/settings.json"
  link_managed_file \
    "$DOTFILES_DIR/vscode/keybindings.json" \
    "$HOME/.config/Code/User/keybindings.json"
  link_managed_file \
    "$DOTFILES_DIR/julia/startup.jl" \
    "$HOME/.julia/config/startup.jl"
}

install_vscode_extensions() {
  local extensions_file="$DOTFILES_DIR/vscode/extensions.txt"
  local extension

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

    code --install-extension "$extension" --force
  done < "$extensions_file"
}

main() {
  install_apt_packages
  install_vscode
  install_oh_my_zsh
  install_juliaup
  install_uv
  stow_dotfiles
  link_extra_files
  install_vscode_extensions

  log "Ubuntu setup complete."
}

main "$@"
