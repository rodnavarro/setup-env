#!/usr/bin/env bash
# setup-env for macOS and Linux: a multi-agent Claude Code workspace in a few minutes.
#
#   curl -fsSL https://raw.githubusercontent.com/rodnavarro/skills/main/install.sh | bash
#
# What it does, each step skipped when it's already done:
#   1. Installs Claude Code and herdr, if they're missing.
#   2. Sets herdr's theme to catppuccin (only when you haven't picked one).
#   3. Adds the status line to Claude Code: c 25% | 5h 17%  3h51m | 7d 21%  2d2h | Opus 5.5 | main
#      (needs Node.js; skipped with a note when it isn't installed).
#   4. Creates the herdr workspace "main" with two tabs, "coordinator" and "researcher",
#      each starting Claude Code in its own folder under ~/agents with its role in CLAUDE.md.
#
# Nothing is deleted. Files it changes are backed up next to themselves first (*.bak-<date>).
# SETUP_ENV_SESSION=<name> uses a named herdr session instead of the default one, and
# SETUP_ENV_AGENTS_DIR another folder than ~/agents for the agents' folders.
set -euo pipefail
BASE=https://raw.githubusercontent.com/rodnavarro/skills/main
STAMP=$(date +%Y%m%d-%H%M%S)
HERE=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")

say() { printf '\033[36m==> %s\033[0m\n' "$1"; }
note() { printf '    %s\n' "$1"; }

# A file of this repo: from the clone when run from one, otherwise from GitHub.
asset() {
  if [ -n "$HERE" ] && [ -f "$HERE/$1" ]; then cat "$HERE/$1"; else curl -fsSL "$BASE/$1"; fi
}
backup() { [ -f "$1" ] && cp "$1" "$1.bak-$STAMP" || true; }

# --- 1. Claude Code and herdr ---------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.herdr/bin:$PATH"
if command -v claude >/dev/null; then
  say "Claude Code is installed"
else
  say "Installing Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
if command -v herdr >/dev/null; then
  say "herdr is installed"
else
  say "Installing herdr"
  curl -fsSL https://herdr.dev/install.sh | sh
  command -v herdr >/dev/null || { echo "herdr didn't install. See https://herdr.dev/tui/docs/install/"; exit 1; }
fi
SESSION=()
[ -n "${SETUP_ENV_SESSION:-}" ] && SESSION=(--session "$SETUP_ENV_SESSION")
hd() { herdr "${SESSION[@]}" "$@"; }

# --- 2. herdr theme ---------------------------------------------------------------------------
HERDR_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml"
if [ ! -f "$HERDR_CONFIG" ]; then
  say "herdr theme: catppuccin"
  mkdir -p "$(dirname "$HERDR_CONFIG")"
  asset herdr/config.toml > "$HERDR_CONFIG"
elif ! grep -Eq '^[[:space:]]*\[theme\]' "$HERDR_CONFIG"; then
  say "herdr theme: catppuccin"
  backup "$HERDR_CONFIG"
  printf '\n[theme]\nname = "catppuccin"\nauto_switch = false\n' >> "$HERDR_CONFIG"
else
  say "herdr already has a theme; left as it is"
fi

# --- 3. Claude Code status line ---------------------------------------------------------------
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$CLAUDE_DIR"
if command -v node >/dev/null; then
  asset claude/statusline.cjs > "$CLAUDE_DIR/statusline.cjs"
  SETTINGS="$CLAUDE_DIR/settings.json"
  COMMAND="node \"$CLAUDE_DIR/statusline.cjs\""
  CURRENT=$(node -e 'try{process.stdout.write(require(process.argv[1]).statusLine.command||"")}catch{}' "$SETTINGS" 2>/dev/null || true)
  if [ "$CURRENT" = "$COMMAND" ]; then
    say "Status line is set"
  else
    say "Status line: context, 5h and 7d limits, model, branch"
    [ -n "$CURRENT" ] && note "Replacing your previous status line; it's kept in settings.json.bak-$STAMP"
    backup "$SETTINGS"
    node -e '
      const fs = require("fs"); const [file, command] = process.argv.slice(1);
      let s = {}; try { s = JSON.parse(fs.readFileSync(file, "utf8")); } catch {}
      s.statusLine = { type: "command", command };
      fs.writeFileSync(file, JSON.stringify(s, null, 2) + "\n");' "$SETTINGS" "$COMMAND"
  fi
else
  say "Status line skipped: it needs Node.js (https://nodejs.org). Install it and run this again."
fi

# --- 4. The workspace: main, with a coordinator and a researcher --------------------------------
AGENTS="${SETUP_ENV_AGENTS_DIR:-$HOME/agents}"
for role in coordinator researcher; do
  mkdir -p "$AGENTS/$role"
  [ -f "$AGENTS/$role/CLAUDE.md" ] || asset "roles/$role.md" > "$AGENTS/$role/CLAUDE.md"
done

# Reads one value from herdr's JSON on stdin, without needing jq.
field() { sed -n "s/.*\"$1\":\"\\([^\"]*\\)\".*/\\1/p" | head -1; }

if ! hd status server 2>&1 | grep -q 'status: running'; then
  say "Starting the herdr server"
  nohup herdr "${SESSION[@]}" server >/dev/null 2>&1 &
  for _ in $(seq 1 20); do sleep 0.5; hd status server 2>&1 | grep -q 'status: running' && break; done
fi

WS=$(hd workspace list | tr '{' '\n' | grep '"label":"main"' | field workspace_id || true)
if [ -n "$WS" ]; then
  say "Workspace main exists"
else
  say "Creating the workspace main"
  OUT=$(hd workspace create --label main --cwd "$AGENTS/coordinator" --no-focus)
  WS=$(echo "$OUT" | field workspace_id)
  hd tab rename "$(echo "$OUT" | field tab_id)" coordinator >/dev/null
  hd pane run "$(echo "$OUT" | field pane_id)" claude >/dev/null
fi

TABS=$(hd tab list --workspace "$WS")
for role in coordinator researcher; do
  echo "$TABS" | grep -q "\"label\":\"$role\"" && continue
  say "Adding the tab $role"
  OUT=$(hd tab create --workspace "$WS" --label "$role" --cwd "$AGENTS/$role")
  hd pane run "$(echo "$OUT" | field pane_id)" claude >/dev/null
done

if [ -n "${SETUP_ENV_SESSION:-}" ]; then say "Done. Open it with: herdr session attach $SETUP_ENV_SESSION"; else say "Done. Open it with: herdr"; fi
note "The first time, each tab asks whether you trust its folder: choose Yes."
note "Then talk to the coordinator; it hands research to the researcher."
