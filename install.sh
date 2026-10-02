#!/usr/bin/env bash
# Dotfiles installer: symlinks whole config DIRECTORIES into place.
# Each app's config becomes a single symlink into this repo, so everything
# inside it (including files you add later, like new themes) is picked up
# automatically. Re-runnable. Existing real files are backed up, never deleted.
#
# New machine = git clone + ./install.sh. That's it.
#
# To manage another app later, add one line to the LINKS list below.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# "<path in repo>:<target under $HOME>"
LINKS=(
  "nvim/.config/nvim:.config/nvim"
  "ghostty/.config/ghostty:.config/ghostty"
  "tmux/.config/tmux:.config/tmux"
)

for entry in "${LINKS[@]}"; do
  src="$DOTFILES_DIR/${entry%%:*}"
  tgt="$HOME/${entry##*:}"
  [ -e "$src" ] || { echo "skip (missing in repo): ${entry%%:*}"; continue; }

  # ghostty is macOS-only; skip on Linux/WSL
  case "$tgt" in *".config/ghostty") [ "$(uname)" = "Darwin" ] || { echo "skip ghostty (not macOS)"; continue; } ;; esac

  if [ -L "$tgt" ]; then
    rm "$tgt"                                   # replace an old symlink
  elif [ -e "$tgt" ]; then
    mkdir -p "$BACKUP/$(dirname "${entry##*:}")"
    mv "$tgt" "$BACKUP/${entry##*:}"            # back up a real file/dir
    echo "backed up $tgt"
  fi
  mkdir -p "$(dirname "$tgt")"
  ln -s "$src" "$tgt"
  echo "linked $tgt -> ${entry%%:*}"
done

[ -d "$BACKUP" ] && echo "Backups: $BACKUP"
echo "Done. Reload your apps (tmux kill-server; reopen Ghostty)."
