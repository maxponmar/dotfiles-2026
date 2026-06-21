# Neovim (LazyVim) Cheatsheet

**Leader key:** `Space`

---

## File Explorer (Neo-tree)

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer |
| `<leader>E` | Open file explorer at current file |
| `o` / `<CR>` | Open file |
| `s` | Open in horizontal split |
| `v` | Open in vertical split |
| `t` | Open in new tab |
| `a` | Add new file/directory (add `/` for directory) |
| `d` | Delete file/directory |
| `r` | Rename |
| `y` | Copy to clipboard |
| `x` | Cut to clipboard |
| `p` | Paste from clipboard |
| `C` | Close directory |
| `z` | Close all directories |
| `H` | Toggle hidden files |
| `I` | Toggle git-ignored files |
| `R` | Refresh |
| `?` | Show help |

---

## Fuzzy Finder (Telescope)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files (fff.nvim — fast fuzzy finder) |
| `<leader>fF` | Find files via Telescope (including hidden) |
| `<leader>fg` | Live grep (search content) |
| `<leader>fw` | Search word under cursor |
| `<leader>fb` | Find open buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fc` | Commands |
| `<leader>fk` | Keymaps |
| `<leader>fd` | Diagnostics |
| `<leader>fs` | Document symbols |
| `<leader>fS` | Workspace symbols |
| `<leader>fm` | Marks |
| `<leader>fj` | Jumplist |
| `<leader>fq` | Quickfix list |
| `<leader>fl` | Location list |
| `<leader>f/` | Search history |
| `<leader>f:` | Command history |
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |
| `<leader>gb` | Git branches |

**Inside Telescope:**

| Key | Action |
|-----|--------|
| `<C-j>` | Move selection down |
| `<C-k>` | Move selection up |
| `<C-q>` | Send selected to quickfix |
| `<C-l>` | Send all to quickfix |
| `<C-v>` | Open in vertical split |
| `<C-x>` | Open in horizontal split |
| `<C-t>` | Open in new tab |
| `q` | Close (in normal mode) |

---

## Easy Motion (Flash)

| Key | Action |
|-----|--------|
| `s` | Jump to any word (shows labels) |
| `S` | Jump to treesitter node |
| `f` / `F` | Jump to character forward/backward |
| `t` / `T` | Jump before character forward/backward |
| `r` | Remote jump (operator-pending mode) |
| `R` | Treesitter search |
| `<C-s>` | Toggle Flash in command-line |

**Usage:** Press `s`, type a few characters, then press the highlighted label to jump.

---

## Fast Navigation & Scrolling

| Key | Action |
|-----|--------|
| `<C-d>` | Scroll down half page (centered) |
| `<C-u>` | Scroll up half page (centered) |
| `<C-f>` | Scroll down full page (centered) |
| `<C-b>` | Scroll up full page (centered) |
| `n` | Next search result (centered) |
| `N` | Previous search result (centered) |
| `gg` | Go to first line |
| `G` | Go to last line |
| `:{number}` | Go to specific line |
| `{number}j` | Jump down N lines (use relative numbers) |
| `{number}k` | Jump up N lines (use relative numbers) |
| `H` | Jump to top of screen |
| `M` | Jump to middle of screen |
| `L` | Jump to bottom of screen |
| `%` | Jump to matching bracket |
| `*` | Search word under cursor forward |
| `#` | Search word under cursor backward |

---

## LSP & Code Intelligence

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `K` | Show hover documentation |
| `<leader>ca` | Code action |
| `<leader>cr` | Rename symbol |
| `<leader>cf` | Format file |
| `<leader>cd` | Show diagnostics (line) |
| `<leader>cD` | Show diagnostics (buffer) |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `[e` | Previous error |
| `]e` | Next error |
| `<leader>ss` | Show document symbols |
| `<leader>sS` | Show workspace symbols |

---

## Debugging (DAP)

| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set conditional breakpoint |
| `<leader>dc` | Continue |
| `<leader>dC` | Run to cursor |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dp` | Pause |
| `<leader>dr` | Toggle REPL |
| `<leader>dl` | Run last |
| `<leader>dt` | Terminate |
| `<leader>dj` | Down (stack frame) |
| `<leader>dk` | Up (stack frame) |
| `<leader>de` | Evaluate expression |
| `<leader>du` | Toggle DAP UI |

---

## Testing

| Key | Action |
|-----|--------|
| `<leader>tt` | Run nearest test |
| `<leader>tT` | Run current file tests |
| `<leader>ta` | Run all tests |
| `<leader>tl` | Run last test |
| `<leader>ts` | Toggle test summary |
| `<leader>to` | Toggle test output |
| `<leader>tS` | Stop tests |
| `<leader>tw` | Toggle watch mode |

---

## Window Management

| Key | Action |
|-----|--------|
| `<leader>h` | Go to left window |
| `<leader>j` | Go to window below |
| `<leader>k` | Go to window above |
| `<leader>l` | Go to right window |
| `<leader>sv` | Split vertically |
| `<leader>sh` | Split horizontally |
| `<leader>se` | Equalize splits |
| `<leader>sx` | Close current split |
| `<leader>to` | New tab |
| `<leader>tx` | Close tab |
| `<leader>tn` | Next tab |
| `<leader>tp` | Previous tab |
| `<C-h>` | Move to left window |
| `<C-j>` | Move to window below |
| `<C-k>` | Move to window above |
| `<C-l>` | Move to right window |

---

## Buffers

| Key | Action |
|-----|--------|
| `<S-h>` | Previous buffer |
| `<S-l>` | Next buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bD` | Delete buffer (force) |
| `<leader>bo` | Delete other buffers |
| `<leader>bb` | Select buffer |
| `<leader>bf` | Find buffer |

---

## Editing

| Key | Action |
|-----|--------|
| `<A-j>` | Move line down |
| `<A-k>` | Move line up |
| `<` / `>` | Unindent/indent (keep selection in visual) |
| `J` | Join lines (keep cursor) |
| `<leader>y` | Copy to system clipboard |
| `<leader>p` | Paste from system clipboard |
| `<leader>Y` | Copy line to system clipboard |
| `<leader>rw` | Rename word under cursor (buffer-wide) |
| `gcc` | Toggle comment (line) |
| `gc` | Toggle comment (visual selection) |
| `.` | Repeat last change |
| `u` | Undo |
| `<C-r>` | Redo |

---

## Search & Replace

| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `:%s/old/new/g` | Replace in entire file |
| `:s/old/new/g` | Replace in current line |
| `:'<,'>s/old/new/g` | Replace in selection |
| `<leader>rw` | Rename word (interactive) |

---

## Git

| Key | Action |
|-----|--------|
| `<leader>gg` | LazyGit |
| `<leader>gb` | Git blame |
| `<leader>gf` | Git file history |
| `<leader>gd` | Git diff |
| `<leader>gh` | Git hunk preview |
| `[h` | Previous hunk |
| `]h` | Next hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghp` | Preview hunk |

---

## Misc

| Key | Action |
|-----|--------|
| `<leader>qq` | Quit all |
| `<leader>qw` | Save and quit all |
| `<leader>l` | Open Lazy (plugin manager) |
| `<leader>m` | Open Mason (LSP installer) |
| `<leader>,` | Switch buffer |
| `<leader>/` | Search in current buffer |
| `<leader>:` | Command history |
| `<leader>?` | Search current directory |

---

## Terminal

| Key | Action |
|-----|--------|
| `<leader>ft` | Toggle terminal |
| `<C-/>` | Toggle terminal (alternate) |
| `<Esc><Esc>` | Exit terminal mode |

---

## Marks

| Key | Action |
|-----|--------|
| `m{a-z}` | Set mark (lowercase = buffer, uppercase = global) |
| `'{a-z}` | Jump to mark |
| `:marks` | List all marks |
| `:delmarks {a-z}` | Delete marks |

---

## Quick Reference: Common Workflows

### Opening a project and finding a file
1. `nvim .` - Open Neovim in current directory
2. `<leader>e` - Open file explorer
3. `<leader>ff` - Fuzzy find file by name
4. `<leader>fg` - Search file contents

### Navigating a large file
1. `<leader>ff` - Find and open file
2. `<leader>fg` or `/` - Search for content
3. `n` / `N` - Jump between matches (centered)
4. `<C-d>` / `<C-u>` - Scroll half page (centered)
5. `{number}j` / `{number}k` - Jump N lines using relative line numbers

### Debugging code
1. `<leader>db` - Set breakpoint
2. `<leader>dc` - Start/continue debugging
3. `<leader>di` / `<leader>do` / `<leader>dO` - Step through code
4. `<leader>du` - Toggle debug UI
5. `<leader>de` - Evaluate expression

### Refactoring
1. `<leader>cr` - Rename symbol (LSP)
2. `<leader>ca` - Code action
3. `<leader>cf` - Format file
4. `v` + `<leader>rw` - Rename in buffer

### Git workflow
1. `<leader>gg` - Open LazyGit
2. `<leader>gb` - View blame
3. `[h` / `]h` - Navigate hunks
4. `<leader>ghs` - Stage hunk
