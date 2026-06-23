# Windows Terminal Vim/Tmux-like Cheat Sheet

Windows has no tmux, so the built-in **Windows Terminal** is configured
(`windows-terminal/settings.json`) to drive panes and tabs from the keyboard,
vim/tmux-style. Windows Terminal has **no prefix chord** (it only supports
single key combos), so every binding is a direct `Alt`-based combo instead of
"press prefix, then key".

> `Alt+<letter>` shadows the shell's Meta keys while Windows Terminal is
> focused — intentional, the same way tmux's prefix consumes its key.

## Pane Focus (vim hjkl)

| Key | Action |
|-----|--------|
| `Alt+h` | Focus pane to the left |
| `Alt+j` | Focus pane below |
| `Alt+k` | Focus pane above |
| `Alt+l` | Focus pane to the right |

## Splitting & Closing Panes

| Key | Action |
|-----|--------|
| `Alt+v` | Split right (vertical), same dir — ≈ tmux `prefix v` |
| `Alt+s` | Split below (horizontal), same dir — ≈ tmux `prefix s` |
| `Alt+z` | Toggle pane zoom — ≈ tmux `prefix z` |
| `Alt+Shift+q` | Close current pane — ≈ tmux `prefix Q` / vim `:q` |

## Pane Resizing (vim HJKL)

| Key | Action |
|-----|--------|
| `Alt+Shift+h` | Resize left |
| `Alt+Shift+j` | Resize down |
| `Alt+Shift+k` | Resize up |
| `Alt+Shift+l` | Resize right |

## Tabs (≈ tmux windows)

| Key | Action |
|-----|--------|
| `Alt+t` | New tab — ≈ tmux `prefix t` |
| `Alt+n` | Next tab — ≈ tmux `prefix n` |
| `Alt+p` | Previous tab — ≈ tmux `prefix p` |
| `Alt+Shift+w` | Close tab |
| `Alt+1`–`Alt+9` | Jump to tab 1-9 — ≈ tmux `prefix 0-9` |

## Copy / Search / Settings

| Key | Action |
|-----|--------|
| `Ctrl+Shift+c` | Copy selection |
| `Ctrl+Shift+v` | Paste |
| `Alt+/` | Search the scrollback (≈ tmux copy-mode search) |
| `Alt+r` | Open settings (Windows Terminal hot-reloads on save) |

## Appearance

- **Font:** `MesloLGS NF` (the Nerd Font Powerlevel10k expects) — installed
  per-user by `install.ps1`, applied to every profile via `profiles.defaults`.
- **Transparency:** `opacity: 80` + `useAcrylic: true` — a frosted, blurred
  see-through window (matches the kitty/Alacritty configs). Drop `useAcrylic`
  to `false` for plain transparency, or raise `opacity` toward `100` for opaque.

## Deploy / reload

- Installed by `install.ps1` (`-WindowsTerminal` for just this component); it
  backs up your existing `settings.json` first.
- Windows Terminal **hot-reloads** `settings.json` on save — no restart needed.
- Edit the source at `windows-terminal/settings.json`, then re-run
  `.\install.ps1 -WindowsTerminal` to push the change (it's copied, not linked).

---
*No prefix key — bindings are direct `Alt` combos. Built-in defaults
(`Ctrl+Shift+f` find, `Ctrl+Shift+d` duplicate tab, etc.) still apply unless
overridden above.*
