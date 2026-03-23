#!/bin/sh
# mcli installer

set -eu

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="mcli"
INSTALL_PATH="${INSTALL_DIR}/${BINARY_NAME}"
RAW_BASE_URL="https://raw.githubusercontent.com/milvasic/mcli/main"

# ──────────────────────────────────────────────────────────────────────────────
# Colors & logging (matching mcli style)
# ──────────────────────────────────────────────────────────────────────────────
RED="\033[0;31m"
GREEN="\033[0;32m"
BOLD="\033[1m"
RESET="\033[0m"

log()   { printf "\n${BOLD}=== %s ===${RESET}\n" "$1"; }
error() { printf "${RED}ERROR:${RESET} %s\n" "$1" >&2; }
ok()    { printf "${GREEN}%s${RESET}\n" "$1"; }

# ──────────────────────────────────────────────────────────────────────────────
# Usage
# ──────────────────────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
mcli installer — install, update, or uninstall mcli.

Usage:
  install.sh [options]

Options:
  --uninstall   Remove mcli from /usr/local/bin
  --yes, -y     Auto-approve upgrade (useful for non-interactive / CI)
  --help        Show this message

Examples:
  # Install or update interactively
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/main/install.sh)"

  # Install or update non-interactively
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/main/install.sh)" -- --yes

  # Uninstall
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/milvasic/mcli/main/install.sh)" -- --uninstall
EOF
  exit 1
}

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

# Returns 0 if sudo is needed to write to INSTALL_DIR
need_sudo() {
  ! [ -w "$INSTALL_DIR" ]
}

# Run a command, prepending sudo if necessary
run_cmd() {
  if need_sudo; then
    sudo "$@"
  else
    "$@"
  fi
}

# Extract VERSION="X.Y.Z" from a file
extract_version() {
  grep -m1 '^VERSION=' "$1" | sed 's/^VERSION="//;s/"$//'
}

# Compare two semver strings (X.Y.Z).
# Prints: greater | lesser | equal
version_compare() {
  local v1="$1" v2="$2"

  if [ "$v1" = "$v2" ]; then
    echo "equal"
    return
  fi

  local i n1 n2
  for i in 1 2 3; do
    n1="$(echo "$v1" | cut -d. -f"$i")"
    n2="$(echo "$v2" | cut -d. -f"$i")"
    n1="${n1:-0}"
    n2="${n2:-0}"
    if [ "$n1" -gt "$n2" ]; then
      echo "greater"
      return
    elif [ "$n1" -lt "$n2" ]; then
      echo "lesser"
      return
    fi
  done

  echo "equal"
}

# Download mcli to a temp file; sets TMPFILE variable
download_mcli() {
  TMPFILE="$(mktemp)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${RAW_BASE_URL}/mcli" -o "$TMPFILE"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMPFILE" "${RAW_BASE_URL}/mcli"
  else
    error "Neither curl nor wget found. Please install one and try again."
    exit 1
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Install / Update
# ──────────────────────────────────────────────────────────────────────────────
do_install() {
  log "mcli installer"

  download_mcli
  trap 'rm -f "$TMPFILE"' EXIT

  local repo_version
  repo_version="$(extract_version "$TMPFILE")"

  if [ -z "$repo_version" ]; then
    error "Could not determine version from remote script."
    exit 1
  fi

  # ── Fresh install ──────────────────────────────────────────────────────
  if [ ! -f "$INSTALL_PATH" ]; then
    run_cmd install -m 755 "$TMPFILE" "$INSTALL_PATH"
    ok "mcli v${repo_version} installed to ${INSTALL_PATH}"
    return
  fi

  # ── Already installed — compare versions ───────────────────────────────
  local installed_version
  installed_version="$(extract_version "$INSTALL_PATH")"

  if [ -z "$installed_version" ]; then
    error "Could not determine version of installed mcli at ${INSTALL_PATH}."
    exit 1
  fi

  local cmp
  cmp="$(version_compare "$repo_version" "$installed_version")"

  case "$cmp" in
    equal)
      ok "mcli v${installed_version} is already installed and up to date."
      ;;
    greater)
      if [ "$auto_yes" = true ]; then
        run_cmd install -m 755 "$TMPFILE" "$INSTALL_PATH"
        ok "mcli updated from v${installed_version} to v${repo_version}."
      elif [ -t 0 ]; then
        printf "Update mcli from ${BOLD}v%s${RESET} to ${BOLD}v%s${RESET}? [y/N] " \
          "$installed_version" "$repo_version"
        read -r reply
        case "$reply" in
          [Yy]|[Yy][Ee][Ss])
            run_cmd install -m 755 "$TMPFILE" "$INSTALL_PATH"
            ok "mcli updated from v${installed_version} to v${repo_version}."
            ;;
          *)
            echo "Update cancelled."
            ;;
        esac
      else
        error "A newer version (v${repo_version}) is available (installed: v${installed_version})."
        error "Run interactively or pass --yes to auto-approve the update."
        exit 1
      fi
      ;;
    lesser)
      error "Installed version (v${installed_version}) is newer than remote (v${repo_version}). Aborting."
      exit 1
      ;;
  esac
}

# ──────────────────────────────────────────────────────────────────────────────
# Uninstall
# ──────────────────────────────────────────────────────────────────────────────
do_uninstall() {
  log "mcli uninstaller"

  if [ ! -f "$INSTALL_PATH" ]; then
    echo "mcli is not installed at ${INSTALL_PATH}. Nothing to do."
    return
  fi

  run_cmd rm -f "$INSTALL_PATH"
  ok "mcli removed from ${INSTALL_PATH}."

  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mcli"
  if [ -d "$config_dir" ]; then
    rm -rf "$config_dir"
    ok "Configuration directory removed: ${config_dir}"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Argument parsing & dispatch
# ──────────────────────────────────────────────────────────────────────────────
action="install"
auto_yes=false

for arg in "$@"; do
  case "$arg" in
    --uninstall)  action="uninstall" ;;
    --yes|-y)     auto_yes=true ;;
    --help|-h)    usage ;;
    *)
      error "Unknown option: $arg"
      usage
      ;;
  esac
done

case "$action" in
  install)    do_install   ;;
  uninstall)  do_uninstall ;;
esac
