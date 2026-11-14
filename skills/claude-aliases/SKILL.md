---
name: claude-aliases
description: Creates and maintains Claude Code aliases such as claude-work, a command that starts Claude Code with its own login, settings, skills, memory and history, kept apart from every other alias on the computer. Use when someone asks to add, list, fix, rename or remove a Claude alias or profile, or to keep a work Claude account separate from a personal or other account on the same computer.
---

# Claude aliases

An alias is a short command, like `claude-work`, that starts Claude Code with its own settings folder. Everything Claude keeps lives in that folder, so each alias has its own:

- login (which Claude account and organization the work is billed to and governed by),
- settings, status bar, permissions and connectors,
- skills,
- memory and past conversations (`claude-work --resume` shows only that alias's sessions).

Plain `claude` keeps using the default folder, `~/.claude`. Claude Code itself is installed once and shared, so updating it updates every alias.

How it works: Claude Code reads its settings folder from the `CLAUDE_CONFIG_DIR` environment variable. An alias is a tiny launcher that sets that variable for one run and then starts `claude`.

**The example used throughout is `claude-work`**, with the settings folder `~/.claude-work`, signed in to a work Claude account. For another alias, replace `work` with its name everywhere.

The person running this is probably not an engineer. Do every step yourself, explain in plain words, and say at the end whether it worked.

## Naming

- Alias: `claude-<name>`. Settings folder: `~/.claude-<name>`. Always the same `<name>` in both.
- `<name>` is short, lowercase letters, digits and hyphens: `work`, not `My Work Account`.
- Never reuse a name for a different account. Make a new alias instead, so old conversations stay with the account they belong to.

## Create an alias

1. **Find where launchers go.** Use `~/.local/bin` (on Windows `C:\Users\<name>\.local\bin`). The Claude Code installer usually puts `claude` there, so it's normally on the PATH already. Check with `claude --version` and by seeing where `claude` lives (`where claude` on Windows, `command -v claude` on Mac). If `~/.local/bin` isn't on the PATH, say so and ask before changing the PATH.
2. **Check the name is free:** no `claude-<name>` launcher in that folder and no `~/.claude-<name>` folder. If either exists, the alias may already be set up: go to "Fix an alias" instead.
3. **Create the settings folder** `~/.claude-<name>` (empty is fine).
4. **Write the launcher.**

   **Windows:** create `~/.local/bin/claude-work.cmd` with exactly:

   ```bat
   @echo off
   setlocal
   set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-work"
   claude %*
   ```

   `setlocal` keeps the variable inside this one run, so plain `claude` in the same window still uses the default folder. `%*` passes everything typed after the alias through, so `claude-work --resume` works.

   **Mac or Linux:** create `~/.local/bin/claude-work` with exactly:

   ```sh
   #!/bin/sh
   CLAUDE_CONFIG_DIR="$HOME/.claude-work" exec claude "$@"
   ```

   Then make it runnable: `chmod +x ~/.local/bin/claude-work`.

5. **Check it starts:** `claude-work --version` prints the same version as `claude --version`. Then check plain `claude` still points at the default folder: on Windows, `echo %CLAUDE_CONFIG_DIR%` in the same window prints nothing new; on Mac, `echo $CLAUDE_CONFIG_DIR` is unchanged.
6. **Sign it in.** Tell the person to open a new terminal, run `claude-work`, and type `/login` to sign in with the account this alias is for (for `claude-work`, their work email). Signing in is theirs to do: never type a password or code for them.
7. **Confirm the account.** In that session, `/status` shows the account and organization. If it shows the wrong one, `/logout` and `/login` again inside the alias. This doesn't touch the other aliases.

## Set it up like the others

A new alias starts empty: no status bar, no skills, no permissions. Ask what the person wants carried over, then copy only that:

- **Skills:** copy the skill folders they want into `~/.claude-work/skills/`. Skills from a shared repository go in the alias's `skills` folder, not `~/.claude/skills`.
- **Status bar:** run the `set-status-bar` skill from inside `claude-work`. It installs into the folder of the session it runs in: the script goes to `~/.claude-work/statusline.cjs` and `~/.claude-work/settings.json` points at that copy. Never point an alias's `statusLine` at another folder's script (such as `~/.claude/statusline.cjs`): the aliases would share it, and changing or removing one would change or break the others. If the account's organization sets the status bar in its managed settings, there's nothing to do: the firm's plugin keeps a copy in the alias's own folder.
- **Settings:** if they want the same permissions or preferences, copy the relevant keys from `~/.claude/settings.json` into `~/.claude-work/settings.json`. Never copy the whole folder: it would carry the other login, history and memory across.
- **Instructions:** a personal `CLAUDE.md` belongs to one alias. `~/.claude-work/CLAUDE.md` is where instructions for this account go.

## Keep several aliases

**List them.** The aliases are the `claude-*` launchers in `~/.local/bin`, and each should have a matching `~/.claude-*` folder. Show the person a short table: alias, folder, and whether both exist. A launcher with no folder, or a folder with no launcher, is half an alias: say which and offer to fix it.

**Know which one you're in.** `/status` inside a session shows the account. Saying the account's name when starting work avoids running work for one account under another account's login.

**Update Claude Code once.** Updating `claude` (`claude update`, or however it was installed) updates every alias, since they all start the same program.

**Change something in every alias**, like a new shared skill: do it once per folder, `~/.claude/` and each `~/.claude-<name>/`, and list which folders were changed.

**Rename an alias:**
1. Make sure no session of it is running.
2. Rename the folder (`~/.claude-old` to `~/.claude-new`) and the launcher file, then change the folder name inside the launcher.
3. Run `claude-new --version`, then `/status` inside it to confirm it's still signed in.

Past conversations move with the folder. Anything that referred to the old command (shortcuts, scripts, notes) needs the new name.

**Remove an alias:**
1. Ask first and say what goes: its login, settings, skills, memory and every past conversation in that folder. This can't be undone.
2. Delete the launcher. Then, only if the person confirms, delete the `~/.claude-<name>` folder. If they're unsure, rename it to `~/.claude-<name>.old` instead, which keeps everything and disables nothing else.

## Fix an alias

- **`claude-work` is not recognized / command not found:** the launcher isn't in a folder on the PATH, or on Mac it isn't executable (`chmod +x`). Open a new terminal after changing the PATH.
- **It opens the wrong account:** it's probably plain `claude` being run, or the launcher points at the wrong folder. Read the launcher and check the folder name, then `/status`.
- **It asks to log in every time:** the folder name in the launcher doesn't match the folder that exists, so Claude starts a fresh empty one. Make them match.
- **The status bar is missing, or changed in several aliases at once:** read `statusLine` in the alias's `settings.json`. If it points into another alias's folder (often `~/.claude/statusline.cjs`), run `set-status-bar` inside this alias so it gets its own copy.
- **Plain `claude` started using the alias's account:** `CLAUDE_CONFIG_DIR` was set permanently somewhere (Windows environment variables, or a `.zshrc`/`.bashrc` line). Remove that permanent setting: the launchers are the only place it should be set.

## What it doesn't cover

- The Claude desktop app and the VS Code extension don't use these launchers; they have their own sign-in.
- An alias only separates what's on this computer. Which account an organization's data may go through is that organization's policy, not this skill.
