#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

main() {
  local os_name
  os_name="$(uname -s)"

  case "$os_name" in
    Darwin)
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
    exec "$SCRIPT_DIR/install-ubuntu.sh"
  fi

  printf 'Unsupported Linux distribution: %s\n' "${PRETTY_NAME:-unknown}" >&2
  printf 'This installer currently supports Ubuntu 22.04 or later.\n' >&2
  exit 1
}

main "$@"
