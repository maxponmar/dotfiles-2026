#!/usr/bin/env python3
"""Claude Code custom status line.

Reads the status JSON from stdin (schema:
https://code.claude.com/docs/en/statusline.md) and prints a single line:

    <dir>  <branch> | <model> | ctx <pct>% | $<cost> | 5h <pct>% (<reset>) | wk <pct>% (<reset>)

  - dir:    current working directory (basename)
  - branch: current git branch (omitted outside a git repo)
  - model:  current model display name
  - ctx:   context-window utilization
  - $:     session cost in USD (Claude bills subscriptions, but this value is
           the API-pricing equivalent of the tokens used)
  - 5h:    5-hour rolling rate-limit usage + time until reset
  - wk:    7-day (weekly) rate-limit usage + time until reset

Rate-limit segments only appear for Pro/Max subscribers after the first API
response, so each is rendered only when present.
"""

import json
import os
import subprocess
import sys
import time

# ANSI 256-color helpers ----------------------------------------------------
RESET = "\033[0m"
DIM = "\033[2m"


def fg(code):
    return f"\033[38;5;{code}m"


SEP = f"{DIM} | {RESET}"

GREEN = fg(71)
YELLOW = fg(179)
RED = fg(167)
BLUE = fg(75)
GREY = fg(245)
PURPLE = fg(140)
CYAN = fg(80)


def usage_color(pct):
    """Green / yellow / red by how full a gauge is."""
    if pct is None:
        return GREY
    if pct >= 80:
        return RED
    if pct >= 50:
        return YELLOW
    return GREEN


def fmt_reset(epoch):
    """Compact 'time until reset', e.g. 2h12m or 47m."""
    if not epoch:
        return None
    delta = int(epoch) - int(time.time())
    if delta <= 0:
        return "now"
    h, rem = divmod(delta, 3600)
    m = rem // 60
    if h:
        return f"{h}h{m:02d}m"
    return f"{m}m"


def git_branch(cwd):
    """Current git branch in *cwd*, or None if not a repo / detached HEAD."""
    try:
        out = subprocess.run(
            ["git", "branch", "--show-current"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=1,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    return out.stdout.strip() or None


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return

    segments = []

    # Working directory + git branch ----------------------------------------
    cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd")
    if cwd:
        loc = f"{CYAN}{os.path.basename(cwd)}{RESET}"
        branch = git_branch(cwd)
        if branch:
            loc += f" {GREEN} {branch}{RESET}"
        segments.append(loc)

    # Model -----------------------------------------------------------------
    model = (data.get("model") or {}).get("display_name") or "?"
    segments.append(f"{PURPLE}{model}{RESET}")

    # Context utilization ---------------------------------------------------
    ctx = data.get("context_window") or {}
    pct = ctx.get("used_percentage")
    if pct is not None:
        c = usage_color(pct)
        segments.append(f"{GREY}ctx {RESET}{c}{round(pct)}%{RESET}")

    # API-equivalent cost ---------------------------------------------------
    cost = (data.get("cost") or {}).get("total_cost_usd")
    if cost is not None:
        segments.append(f"{BLUE}${cost:.2f}{RESET}")

    # Rate limits (Pro/Max only, after first API response) ------------------
    rl = data.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "wk")):
        window = rl.get(key)
        if not window:
            continue
        wpct = window.get("used_percentage")
        if wpct is None:
            continue
        c = usage_color(wpct)
        seg = f"{GREY}{label} {RESET}{c}{round(wpct)}%{RESET}"
        reset = fmt_reset(window.get("resets_at"))
        if reset:
            seg += f"{DIM} ({reset}){RESET}"
        segments.append(seg)

    sys.stdout.write(SEP.join(segments))


if __name__ == "__main__":
    main()
