# Dotfiles

Personal development environment configuration files.

## Contents

| Tool | Directory | Description |
|------|-----------|-------------|
| Zsh | `zsh/` | Shell configuration with Oh My Zsh, Powerlevel10k, and plugins |
| Tmux | `tmux/` | Terminal multiplexer with Vim-like keybindings |
| Neovim | `nvim/` | LazyVim setup with LSP, DAP, and multi-language support |
| Claude Code | `claude/` | `settings.json` (Vim mode) and a custom `statusline.py` |

> Planned: Opencode configs

## Quick Start

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
   ```

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

## Claude Code

`claude/settings.json` enables Vim editor mode and a custom status line. The
status line (`claude/statusline.py`, run with `python3`) shows the model,
context utilization, API-equivalent cost, and 5-hour / weekly rate-limit usage.
The status line command in `settings.json` references the script by absolute
path (`$HOME/repositories/dotfiles/claude/statusline.py`), so clone the repo to
`~/repositories/dotfiles` (or edit that path). Restart Claude Code after
symlinking for the settings to take effect.
