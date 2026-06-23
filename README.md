# Dotfiles

Personal development environment configuration files.

## Contents

| Tool | Directory | Description |
|------|-----------|-------------|
| Zsh | `zsh/` | Shell configuration with Oh My Zsh, Powerlevel10k, and plugins |
| Tmux | `tmux/` | Terminal multiplexer with Vim-like keybindings |
| Neovim | `nvim/` | LazyVim setup with LSP, DAP, and multi-language support |
| Claude Code | `claude/` | `settings.json` (Vim mode) and a custom `statusline.py` |
| Kitty | `kitty/` | GPU terminal: Nerd Font + transparent background |
| Alacritty | `alacritty/` | GPU terminal for Windows+WSL: Nerd Font, transparency, launches Ubuntu |
| Windows Terminal | `windows-terminal/` | Native Windows terminal made vim/tmux-like (no tmux on Windows): Nerd Font + transparency |

> Opencode: `zsh/.zshrc` adds `~/.opencode/bin` to `PATH`. Dedicated Opencode
> configs are still planned.

## Quick Start

### Automated install (recommended)

Clone the repo and run `install.sh`. It auto-detects your platform (Linux, WSL2,
or macOS) and package manager (apt/dnf/pacman/zypper/brew), installs
dependencies, sets up Oh My Zsh + Powerlevel10k + plugins + fzf, configures
Claude Code, and symlinks the configs — **backing up anything it would
overwrite** so the change is reversible.

```bash
git clone <repo-url> ~/repositories/dotfiles
cd ~/repositories/dotfiles
./install.sh                 # everything
```

Partial installs — pick only what you want:

```bash
./install.sh --nvim --tmux   # just Neovim + tmux
./install.sh --zsh           # shell only (zsh + p10k + plugins + aliases)
./install.sh --claude        # Claude Code only
./install.sh --alacritty     # Alacritty config (WSL: copied to Windows %APPDATA%)
./install.sh --aliases       # add the aliases to your existing shell, nothing else
```

Useful flags:

```bash
./install.sh --dry-run       # show what would happen, change nothing
./install.sh --no-deps       # only create symlinks, skip installing packages
./install.sh --with-go --with-dotnet   # also install the Go / .NET LSP toolchains
./install.sh --alacritty --wsl-distro Debian   # Alacritty launches/defaults a non-Ubuntu distro
./install.sh --help          # full usage
```

### Native Windows 11 (PowerShell)

For Windows **without** WSL, use `install.ps1` instead — it sets up Neovim,
Alacritty, and Windows Terminal (no tmux on Windows, so Windows Terminal is
configured vim/tmux-like). It winget-installs the dependencies, installs the
**MesloLGS NF** font per-user (no admin), junctions the nvim config into
`%LOCALAPPDATA%\nvim`, deploys the PowerShell-shell Alacritty config
(`alacritty/alacritty.windows.toml`) to `%APPDATA%\alacritty\`, and deploys the
Windows Terminal config (`windows-terminal/settings.json`) to the Terminal's
`LocalState`. It also appends `windows-terminal/powershell-profile.ps1` to your
PowerShell 7 `$PROFILE` so new tabs and split panes open in the **current
directory** (PowerShell only reports its working directory to Windows Terminal
once this OSC 9;9 shell integration is in place — open a new pwsh tab after
install for it to take effect).

Run it with **no switch** for an interactive menu that lets you pick exactly
which components to set up (and whether to install deps / dry-run) — so you can
re-run just one piece, e.g. only Windows Terminal, without redoing everything.
Pass a component switch (or `-All`) to skip the menu for scripted runs.

```powershell
git clone <repo-url> $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1                    # interactive menu: pick components + options
.\install.ps1 -All               # everything, no menu
.\install.ps1 -Alacritty         # just Alacritty
.\install.ps1 -WindowsTerminal   # just Windows Terminal
.\install.ps1 -DryRun            # show what would happen, change nothing
```

Windows Terminal has no tmux-style prefix, so the bindings are direct `Alt`
combos (`Alt+h/j/k/l` to move between panes, `Alt+v`/`Alt+s` to split,
`Alt+1`-`9` for tabs). See the [Windows Terminal Cheatsheet](windows-terminal-cheatsheet.md).

> The Windows + WSL setup is different: there, run `install.sh` **inside WSL** —
> it copies the WSL-flavored `alacritty/alacritty.toml` (which launches
> `wsl.exe`) into Windows `%APPDATA%`. `install.ps1` is only for native Windows.

**Undo / restore.** Every run saves displaced files under
`~/.dotfiles-backup/<timestamp>/` and records a manifest. To revert:

```bash
./uninstall.sh               # restore the most recent backup
./uninstall.sh --list        # list available backups
./uninstall.sh --from <timestamp>   # restore a specific one
```

`uninstall.sh` only removes symlinks that still point into this repo and never
overwrites files you changed yourself (use `--force` to override). Each
`install.sh` run creates its own timestamped backup set; if you ran the
installer more than once, your *original* pre-install files live in the
**earliest** backup — restore them with `./uninstall.sh --from <timestamp>`
(see `--list`).

> **WSL note:** install the **MesloLGS NF** font on **Windows** (not inside WSL)
> and set it as your Windows Terminal / VS Code font — the installer prints the
> exact links. Clone into the Linux filesystem (e.g. `~/repositories`), not
> `/mnt/c`, for speed.

### Manual install

If you prefer to do it by hand, the steps below set up the same thing.

### Prerequisites

```bash
sudo apt-get install -y zsh curl git fontconfig tmux neovim ripgrep fd-find npm python3-pip python3-venv luarocks xclip
```

**Note:** For WSL or Wayland, also install `wl-clipboard`:

```bash
sudo apt-get install -y wl-clipboard
```

**Language toolchains:** the Neovim config enables LazyVim language extras whose Mason servers need their toolchain on `PATH`. For Go (`gopls`) and .NET/F# (`fsautocomplete`):

```bash
sudo apt-get install -y golang-go dotnet-sdk-10.0
```

`python3-venv` (above) is required for pip-based Mason tools such as `ruff`.

### Installation

1. **Clone this repo:**

   ```bash
   git clone <repo-url> ~/repositories/dotfiles
   ```

2. **Set zsh as default shell:**

   ```bash
   chsh -s $(which zsh)
   ```

3. **Install Oh My Zsh:**

   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

4. **Install MesloLGS NF font** (required for Powerlevel10k icons):

   ```bash
   mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
   curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
   curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
   curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
   curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
   fc-cache -f -v
   ```

   Then set **MesloLGS NF** as your terminal font.

5. **Install Powerlevel10k:**

   ```bash
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
     ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
   ```

6. **Install plugins:**

   ```bash
   git clone https://github.com/zsh-users/zsh-autosuggestions \
     ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
     ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
   git clone https://github.com/agkozak/zsh-z \
     ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-z
   ```

7. **Install fzf:**

   ```bash
   git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
   ~/.fzf/install --all
   ```

8. **Symlink configs:**

   ```bash
   ln -sf ~/repositories/dotfiles/zsh/.zshrc ~/.zshrc
   ln -sf ~/repositories/dotfiles/zsh/.p10k.zsh ~/.p10k.zsh
   ln -sf ~/repositories/dotfiles/tmux/.tmux.conf ~/.tmux.conf
   ln -sfn ~/repositories/dotfiles/nvim ~/.config/nvim
   mkdir -p ~/.claude
   ln -sf ~/repositories/dotfiles/claude/settings.json ~/.claude/settings.json
   ln -sf ~/repositories/dotfiles/markdownlint/.markdownlint-cli2.yaml ~/.markdownlint-cli2.yaml
   mkdir -p ~/.config/kitty
   ln -sf ~/repositories/dotfiles/kitty/kitty.conf ~/.config/kitty/kitty.conf
   ```

   **Alacritty (Windows + WSL):** Alacritty is a native Windows app, so it can't
   read a config symlinked inside WSL. `./install.sh --alacritty` (run in WSL)
   copies `alacritty/alacritty.toml` to `%APPDATA%\alacritty\alacritty.toml` on
   Windows and sets Ubuntu as the default WSL distro. To do it by hand, copy that
   file to `%APPDATA%\alacritty\` on Windows. Install the **MesloLGS NF** font on
   Windows (see step 11 / the WSL font notes) — fonts inside WSL don't count.
   Because it's a copy (not a symlink), re-run `./install.sh --alacritty` after
   editing the repo file to push the change.

9. **Configure Powerlevel10k** (optional, to customize):

   ```bash
   p10k configure
   ```

10. **Install Neovim plugins and LSP servers:**

    ```bash
    nvim  # Wait for LazyVim to install plugins
    # Then inside Neovim:
    :MasonInstall typescript-language-server eslint-lua vscode-css-language-server \
      vscode-html-language-server tailwindcss-language-server yaml-language-server \
      pyright gopls rust-analyzer clangd netcoredbg java-debug-adapter java-test \
      dockerfile-language-server-nodejs sqls prettier stylua black codelldb
    ```

## Guides

- [Zsh Cheatsheet](zsh-cheatsheet.md) - Plugin features and useful shortcuts
- [Tmux Cheatsheet](tmux-cheatsheet.md) - Vim-like keybindings reference
- [Neovim Cheatsheet](nvim-cheatsheet.md) - LazyVim keybindings for development
- [Aliases Cheatsheet](aliases-cheatsheet.md) - Shell aliases for git, Claude Code, pnpm, .NET, Docker, tmux & nvim
- [Windows Terminal Cheatsheet](windows-terminal-cheatsheet.md) - Vim/tmux-like keybindings for native Windows

## Claude Code

`claude/settings.json` enables Vim editor mode and a custom status line. The
status line (`claude/statusline.py`, run with `python3`) shows the model,
context utilization, API-equivalent cost, and 5-hour / weekly rate-limit usage.
The status line command in `settings.json` references the script by absolute
path (`$HOME/repositories/dotfiles/claude/statusline.py`), so clone the repo to
`~/repositories/dotfiles` (or edit that path). Restart Claude Code after
symlinking for the settings to take effect.
