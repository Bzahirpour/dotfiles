#!/usr/bin/env bash
# Verify the dotfiles setup: tools present, versions high enough, configs
# linked, and the tmux config parses cleanly. Read-only and non-destructive:
# the tmux parse test runs on its OWN socket, so your real sessions are
# never touched. Exit code is non-zero if any check fails.
#
# Usage:
#   ./verify.sh

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

green() { printf "\033[0;32m%s\033[0m" "$*"; }
red()   { printf "\033[0;31m%s\033[0m" "$*"; }
yellow(){ printf "\033[0;33m%s\033[0m" "$*"; }

ok()   { printf "  [%s] %s\n" "$(green PASS)" "$*"; PASS=$((PASS+1)); }
bad()  { printf "  [%s] %s\n" "$(red FAIL)" "$*"; FAIL=$((FAIL+1)); }
warn() { printf "  [%s] %s\n" "$(yellow WARN)" "$*"; }

# version_ge A B  -> true if A >= B
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

echo "Dotfiles verification"
echo "====================="

# ---- Required commands -------------------------------------
echo "Tools:"
for cmd in git tmux nvim rg fd fzf lazygit; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd found ($(command -v "$cmd"))"
  else
    # fd may be installed as fdfind on Ubuntu
    if [ "$cmd" = "fd" ] && command -v fdfind >/dev/null 2>&1; then
      warn "fd missing but fdfind present (symlink it to ~/.local/bin/fd for LazyVim)"
    elif [ "$cmd" = "lazygit" ]; then
      warn "lazygit not found (optional, enables the git UI)"
    else
      bad "$cmd not found"
    fi
  fi
done

# ---- Versions ----------------------------------------------
echo "Versions:"
if command -v nvim >/dev/null 2>&1; then
  NV="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  if version_ge "$NV" "0.10.0"; then ok "Neovim $NV (>= 0.10)"; else bad "Neovim $NV is below 0.10"; fi
fi
if command -v tmux >/dev/null 2>&1; then
  TM="$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)"
  if version_ge "$TM" "3.2"; then ok "tmux $TM (>= 3.2)"; else bad "tmux $TM is below 3.2"; fi
fi

# ---- Config links ------------------------------------------
echo "Configs:"
check_link() {
  local target="$1" label="$2"
  if [ -e "$target" ]; then
    if [ -L "$target" ]; then
      ok "$label linked -> $(readlink "$target")"
    else
      warn "$label exists but is not a symlink (a real file/dir, not managed by this repo)"
    fi
  else
    bad "$label missing ($target)"
  fi
}
check_link "$HOME/.config/tmux/tmux.conf" "tmux.conf"
check_link "$HOME/.config/nvim"           "nvim config"
if [ "$(uname -s)" = "Darwin" ]; then
  check_link "$HOME/.config/ghostty/config" "ghostty config"
fi

# ---- tmux config actually parses ---------------------------
echo "tmux config parse:"
if command -v tmux >/dev/null 2>&1 && [ -e "$HOME/.config/tmux/tmux.conf" ]; then
  ERR="$(tmux -L dotfiles_verify -f "$HOME/.config/tmux/tmux.conf" new-session -d -s verify 2>&1)"
  RC=$?
  tmux -L dotfiles_verify kill-server >/dev/null 2>&1 || true
  if [ $RC -eq 0 ] && [ -z "$ERR" ]; then
    ok "tmux.conf loads with no errors"
  else
    bad "tmux.conf reported: ${ERR:-exit code $RC}"
  fi
else
  warn "skipped (tmux or tmux.conf not available)"
fi

# ---- WSL clipboard bridge ----------------------------------
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "WSL:"
  if command -v win32yank.exe >/dev/null 2>&1; then
    ok "win32yank present (tmux/nvim clipboard will reach Windows)"
  else
    warn "win32yank not found (clipboard yanks to Windows may not work)"
  fi
fi

# ---- Summary -----------------------------------------------
echo "====================="
printf "Result: %s passed, %s failed.\n" "$(green "$PASS")" "$([ "$FAIL" -gt 0 ] && red "$FAIL" || green "$FAIL")"
[ "$FAIL" -eq 0 ]
