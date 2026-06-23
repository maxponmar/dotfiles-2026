# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for a WSL2/Linux dev environment. There is no build, lint, or test step — changes are validated by reloading the relevant tool. The repo is consumed by **symlinking** files into their expected locations (see README.md step 8); editing a file here changes the live config once symlinks are in place.

`install.sh` automates setup cross-platform (Linux / WSL2 / macOS): it detects the OS + package manager (apt/dnf/pacman/zypper/brew), installs deps, sets up the tooling, and creates the symlinks below — backing up anything it displaces to `~/.dotfiles-backup/<timestamp>/` with a TSV manifest. `uninstall.sh` reverses a run from that manifest. Supports partial installs (`--zsh/--tmux/--nvim/--claude/--kitty/--alacritty/--aliases`), `--no-deps`, `--dry-run`, `--restore`, and `--wsl-distro <name>` (the WSL distro Alacritty launches / is set as default; default `Ubuntu`, templated into the copied `alacritty.toml`). Implementation: `scripts/lib/common.sh` (logging, OS detect, backup/manifest, idempotent `link_file`, `copy_file` for targets that can't be symlinked + matching `restore_copy`, restore) and `scripts/lib/packages.sh` (package-manager abstraction + tooling installers). The Alacritty component is the one consumer of `copy_file`: on WSL the native Windows Alacritty can't follow a WSL symlink, so its config is *copied* into Windows `%APPDATA%` (manifest action `copy`, reversed by `restore_copy`); `win_appdata_path` in `packages.sh` resolves that location via `cmd.exe`/`wslpath`. **Scripts must stay bash 3.2 compatible** (macOS ships bash 3.2): no associative arrays, `mapfile`, `${v,,}`/`${v^^}`, negative array indices, or GNU-only flags (`readlink -f`, `tac`, in-place `sed -i`, getopt long options). `usage()` in both scripts prints the leading `#` comment block via awk (stops at the first non-comment line), so help stays correct as the header grows.

`install.ps1` is the **native Windows 11** counterpart (PowerShell ≥ 5.1) — only Neovim + Alacritty (Windows has no tmux, and this path is for native use, not WSL). It winget-installs deps, installs the MesloLGS NF font per-user (no admin), junctions `%LOCALAPPDATA%\nvim` to `nvim/` (junctions need no admin/Developer Mode, unlike symlinks), and copies `alacritty/alacritty.windows.toml` (PowerShell shell, not `wsl.exe`) to `%APPDATA%\alacritty\alacritty.toml`. It backs up displaced files to `%USERPROFILE%\.dotfiles-backup\<timestamp>\`. The bash 3.2 rule does **not** apply to `install.ps1` (it's PowerShell). There are two Alacritty configs: `alacritty.toml` (Windows+WSL, launches the chosen distro) and `alacritty.windows.toml` (native Windows, launches `pwsh.exe`).

| Tool | Source | Symlink target |
|------|--------|----------------|
| Zsh | `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` |
| Tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| Neovim | `nvim/` (whole dir) | `~/.config/nvim` |
| Claude Code | `claude/settings.json` | `~/.claude/settings.json` |
| Kitty | `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| Alacritty (WSL/Linux) | `alacritty/alacritty.toml` | WSL: **copied** to Windows `%APPDATA%\alacritty\alacritty.toml` (distro templated in); native Linux: symlinked to `~/.config/alacritty/alacritty.toml` (skipped on macOS) |
| Alacritty (native Windows) | `alacritty/alacritty.windows.toml` | copied by `install.ps1` to `%APPDATA%\alacritty\alacritty.toml` |
| Neovim (native Windows) | `nvim/` (whole dir) | junctioned to `%LOCALAPPDATA%\nvim` by `install.ps1` |
| markdownlint | `markdownlint/.markdownlint-cli2.yaml` | `~/.markdownlint-cli2.yaml` |

`claude/statusline.py` is referenced by absolute path from `settings.json` (not symlinked); `settings.json`'s `statusLine.command` invokes it via `python3`.

The markdownlint config relaxes `MD013` (line length) and `MD060` (table column style). Neovim lints markdown with `markdownlint-cli2` (via nvim-lint), which only discovers config from the cwd downward — so `nvim/lua/plugins/markdown.lua` passes `--config ~/.markdownlint-cli2.yaml` explicitly to make the relaxed rules apply regardless of where `nvim` was launched. Edit the rule set in `markdownlint/.markdownlint-cli2.yaml` (the symlink source).

## Applying / reloading changes

- **Zsh** — `source ~/.zshrc` or open a new shell.
- **Tmux** — prefix is `C-b`; `prefix + r` reloads `~/.tmux.conf` (binding defined in `tmux/.tmux.conf`).
- **Neovim** — restart `nvim`. Plugin/LSP management is interactive: `:Lazy` for plugins, `:Mason` for LSP servers/formatters/DAP adapters. The full install command list lives in README.md step 11.
- **Claude Code** — restart the CLI; `settings.json` is read at startup. The status line script can be tested standalone by piping a sample JSON payload (see the schema docstring in `claude/statusline.py`) into `python3 claude/statusline.py`.

## Neovim architecture (LazyVim)

This is a LazyVim distribution, not a hand-rolled config. Understanding the layering matters before editing:

- `nvim/init.lua` → bootstraps `nvim/lua/config/lazy.lua`, which clones lazy.nvim and loads `LazyVim/LazyVim` plugins **first**, then the LazyVim "extras" imports, then the local `plugins` spec on top to override. This order matters: LazyVim warns if `lazyvim.plugins.extras.*` imports come after your own `plugins` import, so extras are imported directly in `lazy.lua` (NOT in a file under `plugins/`, which would register the `plugins` module before the extras and trip the check).
- `nvim/lua/config/` — `options.lua`, `keymaps.lua`, `autocmds.lua` augment (do not replace) LazyVim defaults. These run for every session.
- `nvim/lua/config/lazy.lua` — enables LazyVim "extras" (language packs, DAP, testing, linting, formatting) via `import` entries in the `spec`. Adding a language = add an `import` line here (before `{ import = "plugins" }`), then `:Mason` install the server. Only import extras that exist in the installed LazyVim version, and whose toolchain is present (e.g. `lang.go` needs Go for `gopls`); a missing extra module aborts the whole config load.
- `nvim/lua/plugins/` — each file returns a lazy.nvim spec table. Files (`telescope.lua`, `flash.lua`, `neo-tree.lua`, `markdown.lua`) override specific plugin options; `fff.lua` adds the `fff.nvim` fast fuzzy file picker (it owns `<leader>ff`, so `telescope.lua` disables that key — search for `false` there). `fff.nvim` builds a Rust binary on install (`:Lazy build fff.nvim`), downloading a prebuilt one or falling back to `cargo`.

When changing editor behavior, decide the right layer: a setting → `config/options.lua`; a keymap → `config/keymaps.lua`; a language toolchain (extra) → `config/lazy.lua`; a plugin's options → a file under `plugins/`.

Custom keymaps deliberately diverge from some LazyVim defaults (e.g. `<leader>h/j/k/l` are remapped to window navigation in `config/keymaps.lua`) — check that file before assuming a key does what stock LazyVim does.

## Conventions

- Cheatsheets (`*-cheatsheet.md`) document the keybindings/aliases for each tool. If you change a keybinding in `tmux/.tmux.conf`, `config/keymaps.lua`, the zsh plugin set, or an alias in `zsh/aliases.zsh`, update the corresponding cheatsheet so it stays accurate.
- Shell aliases live in `zsh/aliases.zsh` (sourced from `.zshrc` by absolute repo path) and are documented in `aliases-cheatsheet.md`. Note: `npm`/`npx` are deliberately aliased to `pnpm`/`pnpx` — never assume `npm` runs real npm in this environment.
- Neovim indentation in config files is 2 spaces, expandtab (matches `options.lua`).
