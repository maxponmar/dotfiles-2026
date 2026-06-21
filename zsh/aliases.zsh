# ============================================================================
# Aliases — sourced from .zshrc
# Documented in aliases-cheatsheet.md (keep the two in sync).
# ============================================================================

# --- Package manager: npm/npx ALWAYS resolve to pnpm --------------------------
# npm is never used directly; everything routes through pnpm.
alias npm='pnpm'
alias npx='pnpx'
alias pn='pnpm'
alias pi='pnpm install'
alias pa='pnpm add'
alias pad='pnpm add -D'
alias prm='pnpm remove'
alias pdx='pnpm dlx'
alias prun='pnpm run'
alias pdev='pnpm dev'
alias pbuild='pnpm build'
alias ptest='pnpm test'

# --- Git ----------------------------------------------------------------------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gb='git branch'
alias gbd='git branch -d'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpu='git push -u origin HEAD'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias gst='git stash'
alias gstp='git stash pop'
alias grh='git reset HEAD'
alias grhh='git reset --hard'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gcp='git cherry-pick'
alias gm='git merge'
alias gwip='git add -A && git commit -m "wip"'

# --- Claude Code --------------------------------------------------------------
alias cc='claude'
alias cca='claude --permission-mode auto'           # automode: act autonomously
alias cce='claude --permission-mode acceptEdits'    # auto-accept file edits
alias ccp='claude --permission-mode plan'           # plan mode (read-only first)
alias ccc='claude --continue'                       # continue most recent session
alias ccr='claude --resume'                         # pick a session to resume
alias ccd='claude --dangerously-skip-permissions'   # bypass ALL permission checks
alias yolo='claude --dangerously-skip-permissions'  # ^ memorable alias

# --- Neovim -------------------------------------------------------------------
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias vimdiff='nvim -d'

# --- Tmux ---------------------------------------------------------------------
alias t='tmux'
alias ta='tmux attach'
alias tat='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias tka='tmux kill-server'

# --- .NET / C# ----------------------------------------------------------------
alias dn='dotnet'
alias dnr='dotnet run'
alias dnb='dotnet build'
alias dnt='dotnet test'
alias dnw='dotnet watch'
alias dnwr='dotnet watch run'
alias dnc='dotnet clean'
alias dnrs='dotnet restore'
alias dna='dotnet add'
alias dnp='dotnet add package'
alias dnpub='dotnet publish'
alias dnnew='dotnet new'
alias dnsln='dotnet sln'
alias dnf='dotnet format'
alias dnef='dotnet ef'                               # EF Core (dotnet-ef tool)

# --- Docker -------------------------------------------------------------------
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'                          # dex <container> <cmd>
alias dlog='docker logs -f'
alias dstop='docker stop $(docker ps -q)'            # stop all running containers
alias dprune='docker system prune -af'              # remove unused data (aggressive)
# Docker Compose (v2 plugin syntax)
alias dc='docker compose'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcb='docker compose build'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'
alias dcp='docker compose ps'
