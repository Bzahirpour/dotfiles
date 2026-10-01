# dotfiles

Portable config for Neovim (LazyVim), tmux, and Ghostty. Works on macOS and Ubuntu/WSL.

## Layout

This repo uses a [GNU stow](https://www.gnu.org/software/stow/)-friendly structure:
each top-level folder is a "package" whose contents mirror your home directory.

```
dotfiles/
├── bootstrap.sh                     # installs tools, runs install.sh, then verify.sh
├── install.sh                       # symlinks configs into place
├── verify.sh                        # checks tools, versions, links, tmux parse
├── .gitignore                       # blocks secrets from being committed
├── tmux/.config/tmux/tmux.conf      # -> ~/.config/tmux/tmux.conf
├── nvim/.config/nvim/               # -> ~/.config/nvim/  (your LazyVim config)
└── ghostty/.config/ghostty/config   # -> ~/.config/ghostty/config (macOS only)
```

## New machine from scratch

On a bare machine with none of the tools installed, `bootstrap.sh` installs
everything (Neovim, tmux, git, ripgrep, fd, fzf, lazygit, and on WSL the
win32yank clipboard bridge), then links the configs:

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

It detects the OS: Homebrew on macOS, apt plus the official Neovim tarball on
Ubuntu/WSL. It is safe to re-run. Open a new shell afterward so PATH changes
take effect, then launch `nvim` once to let LazyVim install its plugins.

What bootstrap does NOT do automatically:
- **macOS**: nothing extra, the Nerd Font is installed via a brew cask.
- **WSL**: the Nerd Font must be installed on the **Windows** side and set as
  your terminal profile's font (Windows Terminal / WezTerm). bootstrap prints a
  reminder about this.

## First-time setup (tools already installed)

If Neovim and tmux are already on the machine, skip bootstrap and just link:

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer backs up any existing real files to `~/.dotfiles-backup/<timestamp>/`
before linking, so nothing is overwritten.

## Verifying

`bootstrap.sh` runs `verify.sh` at the end, but you can run it any time to check
a machine is in good shape:

```sh
./verify.sh
```

It confirms the tools are installed and new enough (Neovim 0.10+, tmux 3.2+),
that the configs are symlinked, and that `tmux.conf` parses with no errors. The
parse test runs on its own throwaway tmux socket, so it never touches your real
sessions. It exits non-zero if anything fails, so it is safe to use in CI or a
provisioning check.

## Adding your Neovim config to the repo

The `nvim` package ships empty (just a `.keep` placeholder). To bring your
existing LazyVim setup under version control:

```sh
rm ~/dotfiles/nvim/.config/nvim/.keep
mv ~/.config/nvim/* ~/.config/nvim/.[!.]* ~/dotfiles/nvim/.config/nvim/ 2>/dev/null
cd ~/dotfiles && ./install.sh nvim
git add -A && git commit -m "Add nvim config"
```

Both machines then pull the same config with `git pull && ./install.sh`.

## Notes per machine

- **macOS**: `install.sh` also stows the Ghostty config. Font (JetBrainsMono
  Nerd Font) and Tokyo Night theme are set there.
- **Ubuntu/WSL**: Ghostty is skipped. The terminal font is a Windows-side
  setting (set JetBrainsMono Nerd Font in Windows Terminal / WezTerm). For
  clipboard yanks from tmux, install `win32yank` so the `y` binding works.

## Prerequisites

tmux 3.2+ and Neovim 0.10+ (both installed for you by `bootstrap.sh`). The tmux
config needs no plugins for the statusline or clipboard; tpm is optional and
commented out at the bottom of `tmux.conf`.
