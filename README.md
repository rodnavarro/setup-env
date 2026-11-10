# setup-env

A multi-agent Claude Code workspace in a few minutes, without setting anything up by hand.

It installs [Claude Code](https://claude.com/claude-code) and [herdr](https://herdr.dev), then opens a workspace where two Claude Code agents work side by side:

- **coordinator**: the one you talk to. It plans the work and hands research to the researcher.
- **researcher**: reads, searches and reports back, without changing anything.

Each runs in its own folder under `~/agents`, with its role in a `CLAUDE.md` you can edit.

## Install

**Windows** (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rodnavarro/setup-env/main/install.ps1 | iex"
```

**macOS and Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/rodnavarro/setup-env/main/install.sh | bash
```

Then run `herdr`. The first time, each tab asks whether you trust its folder: choose **Yes**. Sign in to Claude when it asks.

## What it sets up

| | |
|---|---|
| **Claude Code** | Installed with Anthropic's installer, if it's missing. |
| **herdr** | Installed with herdr's installer, if it's missing, with the **catppuccin** theme (only when you haven't picked a theme). Use it on a black terminal background; the default Windows Terminal profile already is one. |
| **Status line** | At the bottom of Claude Code: context used, the 5-hour and 7-day limits with the time until they reset, the model and the git branch.<br>`c 25% \| 5h 17%  3h51m \| 7d 21%  2d2h \| Opus 5.5 \| main`<br>Green under 50%, yellow from 50%, red from 80%. |
| **Workspace "main"** | Tabs **coordinator** and **researcher**, each starting Claude Code. Open more tabs from herdr, or ask the coordinator to. |

Running it again is safe: every step that's already done is skipped. Nothing is deleted, and any file it changes is backed up next to itself first (`*.bak-<date>`).

## Files

- `install.ps1`, `install.sh`: the installers.
- `claude/statusline.cjs`: the status line (Node.js). `claude/statusline.ps1` does the same on Windows without Node.js.
- `herdr/config.toml`: herdr's theme.
- `roles/coordinator.md`, `roles/researcher.md`: each agent's role, copied to its folder as `CLAUDE.md`.

## Trying it without touching your setup

`SETUP_ENV_SESSION=<name>` puts the workspace in a separate herdr session, `SETUP_ENV_AGENTS_DIR` puts the agents' folders elsewhere, and `CLAUDE_CONFIG_DIR` points Claude Code's settings to another folder.

## License

MIT
