# Shell aliases (sourced from ~/.zshrc and ~/.bashrc).
# Portable: guarded so nothing breaks on a machine without the tool yet.

# Modern ls via eza
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
  alias tree='eza --tree --level=2 --icons'
fi

# --- pywal: match terminal colors to a wallpaper (test) ---
# Usage: setwall ~/Pictures/some-wallpaper.jpg
# Recolors open terminals live and sets the macOS desktop wallpaper.
# Rollback: reload Ghostty (Cmd+Shift+,) to restore the everforest theme.
setwall() {
  [ -f "$1" ] || { echo "usage: setwall <image>"; return 1; }
  command -v wal >/dev/null 2>&1 || { echo "pywal not installed (pipx install pywal16)"; return 1; }
  local img; img="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  wal -n -q -i "$img"                       # writes ~/.cache/wal/colors-ghostty from the template
  if [ "$(uname)" = "Darwin" ]; then
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$img\"" 2>/dev/null
    osascript -e 'tell application "System Events" to keystroke "," using {command down, shift down}' 2>/dev/null  # reload Ghostty
  fi
  echo "wallpaper + palette from $(basename "$img"). If colors did not change, press Cmd+Shift+, in Ghostty."
}
  command -v wal >/dev/null 2>&1 || { echo "pywal not installed (pipx install pywal16)"; return 1; }
  local img; img="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  wal -n -q -i "$img"                                  # generate palette (skip wal's own wallpaper step)
  [ -f "$HOME/.cache/wal/sequences" ] && cat "$HOME/.cache/wal/sequences"   # apply colors to THIS terminal
  if [ "$(uname)" = "Darwin" ]; then
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$img\"" 2>/dev/null
  fi
  echo "applied palette + wallpaper from: $(basename "$img")"
}
