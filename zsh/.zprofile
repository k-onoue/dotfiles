# zsh login-shell configuration managed by dotfiles.
# Put environment setup here so GUI terminals and SSH sessions start consistently.

# Load Homebrew environment early on macOS.
if [ "$(uname -s)" = "Darwin" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Make PATH entries unique while preserving order.
typeset -U path PATH
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.juliaup/bin"
  "$HOME/.elan/bin"
  $path
)
export PATH

# Keep login-shell-only local overrides out of Git.
if [ -r "$HOME/.zprofile.local" ]; then
  source "$HOME/.zprofile.local"
fi
