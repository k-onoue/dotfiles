# zsh runtime configuration managed by dotfiles.
# Keep machine-specific secrets and project-specific settings out of this file.

# Make PATH entries unique while preserving order.
typeset -U path PATH

# User-level tools. uv installs commands in ~/.local/bin on Linux by default.
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.juliaup/bin"
  "$HOME/.elan/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/usr/local/bin"
  "/usr/local/sbin"
  $path
)
export PATH

# Oh My Zsh. The installer is configured not to overwrite this managed file.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="candy"
plugins=(
  git
)

if [ -r "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  plugins+=(
    zsh-autosuggestions
  )
fi

if command -v fzf >/dev/null 2>&1; then
  plugins+=(
    fzf
  )
fi

if [ -r "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

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

# zoxide provides directory history jumping with z and zi.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
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

# Ubuntu packages fd as fdfind to avoid a name conflict.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# fzf key bindings and completion.
if command -v brew >/dev/null 2>&1; then
  FZF_PREFIX="$(brew --prefix fzf 2>/dev/null || true)"
  if [ -n "$FZF_PREFIX" ] && [ -r "$FZF_PREFIX/shell/key-bindings.zsh" ]; then
    source "$FZF_PREFIX/shell/key-bindings.zsh"
  fi
  if [ -n "$FZF_PREFIX" ] && [ -r "$FZF_PREFIX/shell/completion.zsh" ]; then
    source "$FZF_PREFIX/shell/completion.zsh"
  fi
  unset FZF_PREFIX
fi

if [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [ -r /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# uv manages Python versions and project environments.
if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh 2>/dev/null)"
fi

# juliaup installs Julia launchers in ~/.juliaup/bin, which is added above.
if command -v juliaup >/dev/null 2>&1; then
  eval "$(juliaup completions zsh 2>/dev/null || true)"
fi

# Herdr is the primary multiplexer for remote Codex work.
if command -v herdr >/dev/null 2>&1; then
  eval "$(herdr completion zsh 2>/dev/null || true)"
fi

# iTerm2 shell integration is optional and only loaded when installed.
if [ -r "$HOME/.iterm2_shell_integration.zsh" ]; then
  source "$HOME/.iterm2_shell_integration.zsh"
fi

# Keep user-local overrides in a separate untracked file when needed.
if [ -r "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
