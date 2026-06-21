# Zsh Cheatsheet

## Plugins Overview

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
