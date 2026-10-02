# dotfiles

Portable config for Neovim (LazyVim), tmux, and Ghostty. macOS and Ubuntu/WSL.

## How it works

Each app's config is a single symlink into this repo:

```
~/.config/nvim     -> nvim/.config/nvim
~/.config/ghostty  -> ghostty/.config/ghostty   (macOS only)
~/.config/tmux     -> tmux/.config/tmux
```

Because whole directories are linked, anything added inside (new themes, new
lua files) is picked up automatically, with no extra steps.

## New machine

```sh
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh      # installs tools, then runs install.sh + verify.sh
```

If the tools are already installed, skip bootstrap and just link:

```sh
./install.sh
```

`install.sh` backs up any existing real config to `~/.dotfiles-backup/<timestamp>/`
before linking. Re-running is safe.

## Updating

```sh
cd ~/dotfiles && git pull   # live configs update instantly (they are symlinks)
```

## Adding another app

Add one line to the `LINKS` list in `install.sh`, put its config under
`<app>/.config/<app>/` in the repo, and re-run `./install.sh`.

## Ghostty themes

Theme files live in `ghostty/.config/ghostty/themes/` and are available to
Ghostty automatically (the whole ghostty dir is linked). Switch by editing the
`theme =` line in `ghostty/.config/ghostty/config`. Included: `kiro-dark`,
`everforest-soft`.

## Notes

- macOS: if Ghostty ignores this config, make sure no stray
  `~/Library/Application Support/com.mitchellh.ghostty/config` is shadowing it
  (move it aside).
- WSL: the terminal font is a Windows-side setting; install `win32yank` for tmux
  clipboard. Ghostty is skipped (macOS only).
