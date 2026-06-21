# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles for a WSL2/Linux dev environment. There is no build, lint, or test step — changes are validated by reloading the relevant tool. The repo is consumed by **symlinking** files into their expected locations (see README.md step 8); editing a file here changes the live config once symlinks are in place.

| Tool | Source | Symlink target |
|------|--------|----------------|
| Zsh | `zsh/.zshrc`, `zsh/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` |
| Tmux | `tmux/.tmux.conf` | `~/.tmux.conf` |
| Neovim | `nvim/` (whole dir) | `~/.config/nvim` |
| Claude Code | `claude/settings.json` | `~/.claude/settings.json` |

`claude/statusline.py` is referenced by absolute path from `settings.json` (not symlinked); `settings.json`'s `statusLine.command` invokes it via `python3`.

## Applying / reloading changes

- **Zsh** — `source ~/.zshrc` or open a new shell.
- **Tmux** — prefix is `C-b`; `prefix + r` reloads `~/.tmux.conf` (binding defined in `tmux/.tmux.conf`).
- **Neovim** — restart `nvim`. Plugin/LSP management is interactive: `:Lazy` for plugins, `:Mason` for LSP servers/formatters/DAP adapters. The full install command list lives in README.md step 11.
- **Claude Code** — restart the CLI; `settings.json` is read at startup. The status line script can be tested standalone by piping a sample JSON payload (see the schema docstring in `claude/statusline.py`) into `python3 claude/statusline.py`.

## Neovim architecture (LazyVim)

This is a LazyVim distribution, not a hand-rolled config. Understanding the layering matters before editing:

- `nvim/init.lua` → bootstraps `nvim/lua/config/lazy.lua`, which clones lazy.nvim and loads `LazyVim/LazyVim` plugins **first**, then imports the local `plugins` spec on top to override.
- `nvim/lua/config/` — `options.lua`, `keymaps.lua`, `autocmds.lua` augment (do not replace) LazyVim defaults. These run for every session.
- `nvim/lua/plugins/` — each file returns a lazy.nvim spec table. `extras.lua` is the key file: it enables LazyVim "extras" (language packs, DAP, testing, linting, formatting) by `import`. Adding a language = add an `import` line here, then `:Mason` install the server. Other files (`telescope.lua`, `flash.lua`, `neo-tree.lua`) override specific plugin options.

When changing editor behavior, decide the right layer: a setting → `config/options.lua`; a keymap → `config/keymaps.lua`; a language toolchain → `plugins/extras.lua`; a plugin's options → a file under `plugins/`.

Custom keymaps deliberately diverge from some LazyVim defaults (e.g. `<leader>h/j/k/l` are remapped to window navigation in `config/keymaps.lua`) — check that file before assuming a key does what stock LazyVim does.

## Conventions

- Cheatsheets (`*-cheatsheet.md`) document the keybindings/aliases for each tool. If you change a keybinding in `tmux/.tmux.conf`, `config/keymaps.lua`, the zsh plugin set, or an alias in `zsh/aliases.zsh`, update the corresponding cheatsheet so it stays accurate.
- Shell aliases live in `zsh/aliases.zsh` (sourced from `.zshrc` by absolute repo path) and are documented in `aliases-cheatsheet.md`. Note: `npm`/`npx` are deliberately aliased to `pnpm`/`pnpx` — never assume `npm` runs real npm in this environment.
- Neovim indentation in config files is 2 spaces, expandtab (matches `options.lua`).
