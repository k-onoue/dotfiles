#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR
PRUNE_VSCODE_EXTENSIONS=false

usage() {
  cat <<'EOF'
Usage: ./install-mac.sh [--prune-vscode-extensions]

Options:
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

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h | --help)
        usage
        exit 0
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
  if ! brew bundle --file "$DOTFILES_DIR/Brewfile"; then
    warn "brew bundle failed; falling back to one-by-one Brewfile installation."
    install_brewfile_entries_individually
  fi
}

install_brewfile_entries_individually() {
  local line
  local kind
  local package
  local failed=false

  while IFS= read -r line || [ -n "$line" ]; do
    kind=""
    package=""

    case "$line" in
      brew\ \"*\")
        kind="formula"
        package="${line#brew \"}"
        package="${package%%\"*}"
        ;;
      cask\ \"*\")
        kind="cask"
        package="${line#cask \"}"
        package="${package%%\"*}"
        ;;
      *)
        continue
        ;;
    esac

    if [ -z "$package" ]; then
      continue
    fi

    case "$kind" in
      formula)
        if brew list --formula "$package" >/dev/null 2>&1; then
          log "Using $package."
          continue
        fi

        log "Installing $package."
        if ! brew install "$package"; then
          warn "Failed to install Homebrew formula: $package"
          failed=true
        fi
        ;;
      cask)
        if brew list --cask "$package" >/dev/null 2>&1; then
          log "Using $package."
          continue
        fi

        log "Installing $package."
        if ! brew install --cask "$package"; then
          warn "Failed to install Homebrew cask: $package"
          failed=true
        fi
        ;;
    esac
  done < "$DOTFILES_DIR/Brewfile"

  if [ "$failed" = true ]; then
    return 1
  fi
}

link_yazi_preview_tools() {
  local formula

  load_homebrew
  if ! command_exists brew; then
    warn "Homebrew is not available; skipping Yazi preview tool linking."
    return
  fi

  for formula in ffmpeg-full imagemagick-full; do
    if ! brew list --formula "$formula" >/dev/null 2>&1; then
      warn "$formula is not installed; skipping link step."
      continue
    fi

    log "Linking $formula for Yazi previews."
    if ! brew link --force --overwrite "$formula"; then
      warn "Failed to link $formula. Yazi previews may use an older command on PATH."
    fi
  done
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

check_managed_file_conflicts() {
  log "Checking for existing managed file conflicts."
  "$DOTFILES_DIR/bin/dotfiles-check-conflicts"
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
  link_managed_file \
    "$DOTFILES_DIR/yazi/.config/yazi/theme.toml" \
    "$HOME/.config/yazi/theme.toml"
  link_managed_file \
    "$DOTFILES_DIR/iterm2/tokyo-night.plist" \
    "$HOME/Library/Application Support/iTerm2/DynamicProfiles/tokyo-night.plist"
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

    run_code_cli --install-extension "$extension" --force
  done < "$extensions_file"
}

write_vscode_extension_diff() {
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
  ensure_homebrew
  install_brew_packages
  link_yazi_preview_tools
  install_oh_my_zsh
  install_zsh_autosuggestions
  install_yazi_tokyo_night_flavor
  install_vscode_extensions
  write_vscode_extension_diff
  check_managed_file_conflicts
  stow_dotfiles
  link_extra_files
  reload_zsh_config

  log "macOS setup complete."
}

main "$@"
