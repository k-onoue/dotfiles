# shellcheck shell=bash
# Bash integration managed by dotfiles.
# Keep this file compatible with non-login interactive Bash sessions.

# Basic aliases shared across macOS and Ubuntu.
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias gst='git status'
alias gco='git checkout'
alias gb='git branch'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Prefer modern replacements when they are installed.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -la --git'
  alias tree='eza --tree'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
fi

function y() {
  local tmp
  local cwd

  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd" || return
  fi
  rm -f -- "$tmp"
}
