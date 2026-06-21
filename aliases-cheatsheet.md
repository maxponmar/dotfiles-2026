# Aliases Cheatsheet

All aliases live in [`zsh/aliases.zsh`](zsh/aliases.zsh) and are sourced from `.zshrc`.
Edit that file to change them, then run `source ~/.zshrc` (or open a new shell).

> The Oh My Zsh `git` plugin also provides many git aliases (`gst`, `glog`, …).
> The set below is the curated personal layer on top of that.

## Package manager — npm/npx always mean pnpm

`npm` is never used directly; both `npm` and `npx` are redirected to pnpm.

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `npm` | `pnpm` | npm is rerouted to pnpm |
| `npx` | `pnpx` | npx is rerouted to pnpx |
| `pn` | `pnpm` | short pnpm |
| `pi` | `pnpm install` | install dependencies |
| `pa` | `pnpm add` | add a dependency |
| `pad` | `pnpm add -D` | add a dev dependency |
| `prm` | `pnpm remove` | remove a dependency |
| `pdx` | `pnpm dlx` | run a package without installing |
| `prun` | `pnpm run` | run a script |
| `pdev` | `pnpm dev` | run the dev script |
| `pbuild` | `pnpm build` | run the build script |
| `ptest` | `pnpm test` | run tests |

## Git

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `g` | `git` | |
| `gs` | `git status -sb` | short status |
| `ga` | `git add` | stage paths |
| `gaa` | `git add -A` | stage everything |
| `gc` | `git commit -m` | commit with message |
| `gca` | `git commit --amend` | amend last commit |
| `gcan` | `git commit --amend --no-edit` | amend, keep message |
| `gco` | `git checkout` | |
| `gcb` | `git checkout -b` | new branch |
| `gsw` | `git switch` | switch branch |
| `gb` | `git branch` | list branches |
| `gbd` | `git branch -d` | delete branch |
| `gp` | `git push` | |
| `gpf` | `git push --force-with-lease` | safe force push |
| `gpu` | `git push -u origin HEAD` | push & set upstream |
| `gpl` | `git pull` | |
| `gf` | `git fetch --all --prune` | fetch & prune |
| `gd` | `git diff` | unstaged diff |
| `gds` | `git diff --staged` | staged diff |
| `gl` | `git log --oneline --graph --decorate -20` | recent log graph |
| `gla` | `git log … --all` | full log graph |
| `gst` | `git stash` | |
| `gstp` | `git stash pop` | |
| `grh` | `git reset HEAD` | unstage |
| `grhh` | `git reset --hard` | discard all changes |
| `grb` | `git rebase` | |
| `grbi` | `git rebase -i` | interactive rebase |
| `gcp` | `git cherry-pick` | |
| `gm` | `git merge` | |
| `gwip` | `git add -A && git commit -m "wip"` | quick work-in-progress commit |

## Claude Code

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `cc` | `claude` | start an interactive session |
| `cca` | `claude --permission-mode auto` | **automode** — acts autonomously |
| `cce` | `claude --permission-mode acceptEdits` | auto-accept file edits, still ask for the rest |
| `ccp` | `claude --permission-mode plan` | plan mode — read-only until you approve |
| `ccc` | `claude --continue` | continue the most recent conversation |
| `ccr` | `claude --resume` | pick a past session to resume |
| `ccd` | `claude --dangerously-skip-permissions` | **bypass ALL permission checks** |
| `yolo` | `claude --dangerously-skip-permissions` | same as `ccd`, memorable name |

> ⚠️ `ccd` / `yolo` skip every permission prompt — only use in a trusted, sandboxed,
> or throwaway directory.

## Neovim

| Alias | Expands to |
|-------|-----------|
| `v` / `vi` / `vim` | `nvim` |
| `vimdiff` | `nvim -d` |

## Tmux

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `t` | `tmux` | |
| `ta` | `tmux attach` | attach to last session |
| `tat` | `tmux attach -t` | attach to named session |
| `tn` | `tmux new -s` | new named session |
| `tl` | `tmux ls` | list sessions |
| `tk` | `tmux kill-session -t` | kill named session |
| `tka` | `tmux kill-server` | kill all sessions |

## .NET / C\#

> Requires the .NET SDK (`dotnet`). EF aliases need the `dotnet-ef` global tool.

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `dn` | `dotnet` | |
| `dnr` | `dotnet run` | |
| `dnb` | `dotnet build` | |
| `dnt` | `dotnet test` | |
| `dnw` | `dotnet watch` | |
| `dnwr` | `dotnet watch run` | hot-reload run |
| `dnc` | `dotnet clean` | |
| `dnrs` | `dotnet restore` | |
| `dna` | `dotnet add` | add reference/package |
| `dnp` | `dotnet add package` | add a NuGet package |
| `dnpub` | `dotnet publish` | |
| `dnnew` | `dotnet new` | scaffold from template |
| `dnsln` | `dotnet sln` | manage the solution file |
| `dnf` | `dotnet format` | format code |
| `dnef` | `dotnet ef` | EF Core migrations etc. |

## Docker

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `d` | `docker` | |
| `dps` | `docker ps` | running containers |
| `dpsa` | `docker ps -a` | all containers |
| `di` | `docker images` | |
| `dex` | `docker exec -it` | `dex <container> <cmd>` |
| `dlog` | `docker logs -f` | follow logs |
| `dstop` | `docker stop $(docker ps -q)` | stop all running containers |
| `dprune` | `docker system prune -af` | remove unused data (aggressive) |
| `dc` | `docker compose` | |
| `dcu` | `docker compose up` | |
| `dcud` | `docker compose up -d` | up, detached |
| `dcd` | `docker compose down` | |
| `dcb` | `docker compose build` | |
| `dcl` | `docker compose logs -f` | follow compose logs |
| `dcr` | `docker compose restart` | |
| `dcp` | `docker compose ps` | |
