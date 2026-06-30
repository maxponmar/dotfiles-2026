# Zsh Cheatsheet

## Startup Directory

New interactive shells opened fresh at `$HOME` jump to `~/Repositories/`
automatically. Terminals already inside a project (editor integrated terminals,
tmux panes, subshells) stay where they are — the jump only fires when `$PWD` is
exactly `$HOME`. Configured at the end of `zsh/.zshrc`.

## Plugins Overview

### vi-mode (Vim editing on the command line)

Vim-style modal editing for the prompt. Press `Esc` to enter **normal** mode,
`i`/`a` to return to **insert** mode. The cursor changes shape per mode (line in
insert, block in normal) and `KEYTIMEOUT=1` keeps the `Esc` switch instant.
Common emacs keys are kept on purpose (see below) so muscle memory still works.

| Key | Mode | Action |
|-----|------|--------|
| `Esc` | insert → normal | Enter normal (command) mode |
| `i` / `a` | normal → insert | Insert before / after cursor |
| `I` / `A` | normal → insert | Insert at line start / end |
| `0` / `$` | normal | Jump to start / end of line |
| `w` / `b` / `e` | normal | Move by word (forward / back / end) |
| `dd` / `cc` | normal | Delete / change whole line |
| `dw` / `cw` | normal | Delete / change word |
| `x` / `r` | normal | Delete char / replace char |
| `u` | normal | Undo |
| `/` `?` | normal | Search history |
| `vv` | normal | Open `$EDITOR` to edit the command |
| `y` / `p` | normal | Yank / paste (synced with system clipboard) |

**Kept emacs bindings (work in both modes):**

| Key | Action |
|-----|--------|
| `Ctrl+A` / `Ctrl+E` | Start / end of line |
| `Ctrl+W` | Delete previous word |
| `Ctrl+R` | History search (fzf — vi-mode loads before fzf so fzf wins) |
| `Ctrl+P` / `Ctrl+N` | Previous / next history entry |

### zsh-autosuggestions

Suggests commands as you type based on history.

| Key | Action |
|-----|--------|
| `→` (right arrow) | Accept full suggestion |
| `Ctrl+→` | Accept one word of suggestion |
| `End` | Accept full suggestion |

### zsh-syntax-highlighting

Colors commands as you type:

- **Green** = valid command
- **Red** = invalid command
- **Underline** = valid path/argument

### zsh-z (Directory Jumping)

Jump to frequently used directories without typing full paths.

| Command | Action |
|---------|--------|
| `z <pattern>` | Jump to most used directory matching pattern |
| `z foo bar` | Jump to directory matching "foo" and "bar" |
| `z -l <pattern>` | List matching directories |
| `z -r <pattern>` | Jump by rank (frecency) |
| `z -t <pattern>` | Jump by most recently used |

**Examples:**

```bash
z dotfiles    # Jump to ~/repositories/dotfiles (if visited before)
z config nvim # Jump to a path containing both "config" and "nvim"
```

### fzf (Fuzzy Finder)

| Key / Command | Action |
|---------------|--------|
| `Ctrl+R` | Search command history |
| `Ctrl+T` | Search files in current directory |
| `Alt+C` | Fuzzy cd into directory |
| `**<Tab>` | Fuzzy completion for paths, variables, etc. |

**Examples:**

```bash
vim **<Tab>        # Fuzzy find files to open
cd **<Tab>         # Fuzzy find directories
kill -9 **<Tab>    # Fuzzy find process IDs
```

## Oh My Zsh Git Plugin

| Alias | Command |
|-------|---------|
| `gst` | `git status` |
| `gco` | `git checkout` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gcmsg` | `git commit -m` |
| `glog` | `git log --oneline --decorate --graph` |
| `gb` | `git branch` |
| `gsta` | `git stash` |
| `gstp` | `git stash pop` |

## Useful Zsh Built-ins

| Key | Action |
|-----|--------|
| `Tab` | Auto-complete |
| `Ctrl+R` | Reverse search history (enhanced by fzf) |
| `Ctrl+A` / `Ctrl+E` | Jump to start/end of line |
| `Ctrl+U` | Clear line before cursor |
| `Ctrl+K` | Clear line after cursor |
| `Alt+B` / `Alt+F` | Move backward/forward one word |
