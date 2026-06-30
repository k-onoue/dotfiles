#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

usage() {
  cat <<'EOF'
Usage: ./install.sh [--server] [--check]

Options:
  --server   Skip VS Code setup for CLI-only Ubuntu servers.
  --check    Check managed file conflicts without installing packages.
  -h, --help Show this help.
EOF
}

SERVER_MODE=false
CHECK_ONLY=false

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
      --check)
        CHECK_ONLY=true
        ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

main() {
  local os_name
  local check_args=()

  parse_args "$@"

  if [ "$SERVER_MODE" = true ]; then
    check_args+=(--skip-vscode)
  fi

  if [ "$CHECK_ONLY" = true ]; then
    exec "$SCRIPT_DIR/bin/dotfiles-check-conflicts" "${check_args[@]}"
  fi

  os_name="$(uname -s)"

  case "$os_name" in
    Darwin)
      if [ "$SERVER_MODE" = true ]; then
        printf 'The --server option is intended for Ubuntu CLI servers.\n' >&2
        exit 2
      fi
      exec "$SCRIPT_DIR/install-mac.sh"
      ;;
    Linux)
      run_linux_installer
      ;;
    *)
      printf 'Unsupported OS: %s\n' "$os_name" >&2
      exit 1
      ;;
  esac
}

run_linux_installer() {
  if [ ! -r /etc/os-release ]; then
    printf 'Cannot detect Linux distribution: /etc/os-release is missing.\n' >&2
    exit 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if [ "${ID:-}" = "ubuntu" ]; then
    if [ "$SERVER_MODE" = true ]; then
      exec "$SCRIPT_DIR/install-ubuntu.sh" --server
    fi
    exec "$SCRIPT_DIR/install-ubuntu.sh"
  fi

  printf 'Unsupported Linux distribution: %s\n' "${PRETTY_NAME:-unknown}" >&2
  printf 'This installer currently supports Ubuntu 22.04 or later.\n' >&2
  exit 1
}

main "$@"
