#!/usr/bin/env bash
# Dotfiles installer. Symlinks config into place using GNU stow when available,
# with a manual-symlink fallback. Existing files are backed up, never clobbered.
#
# Usage:
#   ./install.sh              # installs tmux + nvim (+ ghostty on macOS)
#   ./install.sh tmux nvim    # install only the named packages

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Default package set. Ghostty only makes sense on macOS.
if [ "$#" -gt 0 ]; then
  PACKAGES=("$@")
else
  PACKAGES=(tmux nvim)
  [ "$(uname)" = "Darwin" ] && PACKAGES+=(ghostty)
fi

echo "Dotfiles: $DOTFILES_DIR"
echo "Packages: ${PACKAGES[*]}"

if command -v stow >/dev/null 2>&1; then
  echo "Using GNU stow."
  for pkg in "${PACKAGES[@]}"; do
    # --adopt-free: back up conflicts first so stow doesn't fail
    while IFS= read -r -d '' src; do
      rel="${src#"$DOTFILES_DIR/$pkg/"}"
      target="$HOME/$rel"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
        echo "  backed up $target"
      fi
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
    stow -d "$DOTFILES_DIR" -t "$HOME" -R "$pkg"
    echo "  stowed $pkg"
  done
else
  echo "stow not found, using manual symlinks. (Install stow for cleaner management.)"
  for pkg in "${PACKAGES[@]}"; do
    while IFS= read -r -d '' src; do
      rel="${src#"$DOTFILES_DIR/$pkg/"}"
      target="$HOME/$rel"
      mkdir -p "$(dirname "$target")"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
        echo "  backed up $target"
      fi
      ln -sfn "$src" "$target"
      echo "  linked $target"
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
  done
fi

[ -d "$BACKUP_DIR" ] && echo "Backups saved to: $BACKUP_DIR"
echo "Done. Open a new shell (or: tmux kill-server) to pick everything up."
