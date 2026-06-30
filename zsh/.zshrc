# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  vi-mode
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-z
  fzf
)

# vi-mode: change cursor shape between insert (line) and normal (block) so the
# active mode is visible. KEYTIMEOUT=1 (10ms) removes the ESC -> normal-mode lag
# that the 400ms zsh default otherwise causes. Set before oh-my-zsh sources the
# plugins. vi-mode is listed before fzf above so fzf keeps Ctrl+R for history
# search instead of vi-mode's incremental search.
VI_MODE_SET_CURSOR=true
KEYTIMEOUT=1

source $ZSH/oh-my-zsh.sh

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Aliases (kept in the dotfiles repo, documented in aliases-cheatsheet.md)
[ -f "$HOME/repositories/dotfiles/zsh/aliases.zsh" ] && source "$HOME/repositories/dotfiles/zsh/aliases.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/maximiliano/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Open new interactive shells in the projects directory. Guarded with $PWD ==
# $HOME so it only fires when a terminal opens fresh at home, leaving editor
# terminals, tmux panes, and subshells that already started inside a project
# exactly where they are. The -d check avoids a cd error if the dir is missing.
if [[ -o interactive && "$PWD" == "$HOME" && -d "$HOME/Repositories" ]]; then
  cd "$HOME/Repositories"
fi
