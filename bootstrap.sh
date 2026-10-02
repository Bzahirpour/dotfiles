#!/usr/bin/env bash
# Bootstrap a fresh machine: install tools, then link configs.
# Supports macOS and Ubuntu/WSL. Safe to re-run (idempotent).
#
# Usage:
#   ./bootstrap.sh
#
# After this finishes, open a new shell so PATH changes take effect.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"

log() { printf "\n\033[1;34m==>\033[0m %s\n" "$*"; }

# Add a line to the user's shell rc files only if it's not already there.
add_to_rc() {
  local line="$1"
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    grep -qF -- "$line" "$rc" || printf '\n%s\n' "$line" >>"$rc"
  done
}

# ------------------------------------------------------------
#  macOS
# ------------------------------------------------------------
install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log "Installing packages via brew"
  brew install neovim git ripgrep fd lazygit fzf tmux
  log "Installing JetBrainsMono Nerd Font"
  brew install --cask font-jetbrains-mono-nerd-font || true
}

# ------------------------------------------------------------
#  Ubuntu / WSL
# ------------------------------------------------------------
install_linux() {
  log "Installing base packages via apt"
  sudo apt update
  sudo apt install -y git ripgrep fd-find unzip build-essential curl tmux fzf python3-pip

  # fd is 'fdfind' on Ubuntu; LazyVim expects 'fd'
  mkdir -p "$HOME/.local/bin"
  if command -v fdfind >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  add_to_rc 'export PATH="$HOME/.local/bin:$PATH"'
  export PATH="$HOME/.local/bin:$PATH" # also for this run's verify step

  # Neovim: apt's version is too old, use the official tarball
  if ! command -v nvim >/dev/null 2>&1; then
    log "Installing Neovim (official tarball)"
    case "$ARCH" in
    x86_64) NVIM_PKG="nvim-linux-x86_64" ;;
    aarch64 | arm64) NVIM_PKG="nvim-linux-arm64" ;;
    *)
      echo "Unknown arch $ARCH, install Neovim manually"
      NVIM_PKG=""
      ;;
    esac
    if [ -n "$NVIM_PKG" ]; then
      curl -fsSL -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/latest/download/${NVIM_PKG}.tar.gz"
      sudo rm -rf "/opt/${NVIM_PKG}"
      sudo tar -C /opt -xzf /tmp/nvim.tar.gz
      add_to_rc "export PATH=\"\$PATH:/opt/${NVIM_PKG}/bin\""
      export PATH="$PATH:/opt/${NVIM_PKG}/bin"
    fi
  fi

  # lazygit (not in apt)
  if ! command -v lazygit >/dev/null 2>&1; then
    log "Installing lazygit"
    LG="$(curl -s 'https://api.github.com/repos/jesseduffield/lazygit/releases/latest' |
      grep -Po '"tag_name": *"v\K[^"]*')"
    curl -fsSL -o /tmp/lazygit.tar.gz \
      "https://github.com/jesseduffield/lazygit/releases/download/v${LG}/lazygit_${LG}_Linux_x86_64.tar.gz"
    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
  fi

  # win32yank for clipboard, only under WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if [ ! -e "$HOME/.local/bin/win32yank.exe" ]; then
      log "Installing win32yank (WSL clipboard bridge)"
      curl -fsSL -o /tmp/win32yank.zip \
        https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
      unzip -p /tmp/win32yank.zip win32yank.exe >"$HOME/.local/bin/win32yank.exe"
      chmod +x "$HOME/.local/bin/win32yank.exe"
    fi
    log "Reminder: install JetBrainsMono Nerd Font on the WINDOWS side and set it"
    log "          as the font for your terminal profile (Windows Terminal / WezTerm)."
  fi
}

# ------------------------------------------------------------
#  Run
# ------------------------------------------------------------
case "$OS" in
Darwin) install_macos ;;
Linux) install_linux ;;
*)
  echo "Unsupported OS: $OS"
  exit 1
  ;;
esac

log "Linking configs"
chmod +x "$DOTFILES_DIR/install.sh"
"$DOTFILES_DIR/install.sh"

log "Verifying setup"
chmod +x "$DOTFILES_DIR/verify.sh"
"$DOTFILES_DIR/verify.sh" || log "Some checks did not pass, see above."

log "Done. Open a NEW shell so PATH changes take effect, then run: nvim"
echo "First nvim launch bootstraps LazyVim and installs plugins; then run :LazyHealth."
