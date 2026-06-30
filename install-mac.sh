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

ensure_homebrew() {
  if command_exists brew; then
    log "Homebrew is already installed."
    return
  fi

  log "Installing Homebrew."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew
}

load_homebrew() {
  # Apple Silicon uses /opt/homebrew, while Intel Macs usually use /usr/local.
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brew_packages() {
  load_homebrew

  if ! command_exists brew; then
    printf 'Homebrew installation finished, but brew is not on PATH.\n' >&2
    printf 'Open a new shell or check the Homebrew installation output.\n' >&2
    exit 1
  fi

  log "Installing packages from Brewfile."
  brew bundle --file "$DOTFILES_DIR/Brewfile"
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
    "$HOME/Library/Application Support/Code/User/settings.json"
  link_managed_file \
    "$DOTFILES_DIR/vscode/keybindings.json" \
    "$HOME/Library/Application Support/Code/User/keybindings.json"
  link_managed_file \
    "$DOTFILES_DIR/julia/startup.jl" \
    "$HOME/.julia/config/startup.jl"
}

install_vscode_extensions() {
  local extensions_file="$DOTFILES_DIR/vscode/extensions.txt"
  local extension

  if ! command_exists code; then
    warn "VS Code command 'code' is not available; skipping extension installation."
    warn "Install the shell command from VS Code, then rerun this script."
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
  ensure_homebrew
  install_brew_packages
  install_oh_my_zsh
  stow_dotfiles
  link_extra_files
  install_vscode_extensions

  log "macOS setup complete."
}

main "$@"
