---
name: set-status-bar
description: Sets the Claude Code status line at the bottom of the terminal to show context used, the 5-hour and 7-day plan limits with time to reset, the model and the git branch, like "c 0.0% | 5h 1%  3h51m | 7d 15%  4d15h | Opus 5.5 | master". Use when someone asks to set up, install, fix or reset their status bar or status line.
---

# Set the status bar

Installs the status line for Claude Code in the terminal. When it's done, the bottom of every session shows:

```
c 0.0% | 5h 1%  3h51m | 7d 15%  4d15h | Opus 5.5 | master
```

- `c`: how full this conversation's context is.
- `5h` and `7d`: how much of the plan's 5-hour and weekly limits is used, and the time until each resets.
- The model, then the git branch of the folder the session is in (left out outside a git repository).

Numbers are green under 50%, yellow from 50%, red from 80%. The limits show after the session's first reply: Claude Code only sends them then.

The person running this is probably not an engineer. Do every step yourself, explain in plain words, and say at the end whether it worked.

## Steps

1. **Find Claude's settings folder.** It's `$CLAUDE_CONFIG_DIR` if that variable is set, otherwise `~/.claude` (on Windows `C:\Users\<name>\.claude`). Call it `<config>` below.
2. **Check Node.js** with `node --version`; the status line runs on it, and Claude Code installs usually have it. If it's missing, say so and ask before installing it (Windows: `winget install OpenJS.NodeJS.LTS`; Mac: `brew install node`).
3. **Copy the script.** Copy `scripts/statusline.cjs` from this skill's folder to `<config>/statusline.cjs`, replacing an older copy if there is one.
4. **Point Claude Code at it** in `<config>/settings.json`:
   - Read the file first. If it doesn't exist, create it as `{}`.
   - If it already has a `statusLine` that runs something else, show the person what it is and ask before replacing it.
   - Copy the file to `<config>/settings.json.bak` before changing it.
   - Set only the `statusLine` key and keep every other key exactly as it was:

     ```json
     "statusLine": {
       "type": "command",
       "command": "node \"<config>/statusline.cjs\""
     }
     ```

     Write `<config>` as the full path with forward slashes, e.g. `node "C:/Users/alex/.claude/statusline.cjs"`.
   - Check the file is still valid JSON afterwards.
5. **Test it** by sending it a sample of what Claude Code sends:

   ```
   echo '{"model":{"display_name":"Opus 5.5"},"context_window":{"used_percentage":0},"rate_limits":{"five_hour":{"used_percentage":1,"resets_at":<now + 3h51m, in Unix seconds>},"seven_day":{"used_percentage":15,"resets_at":<now + 4d15h>}},"workspace":{"current_dir":"<a git repository>"}}' | node "<config>/statusline.cjs"
   ```

   It should print `c 0.0% | 5h 1%  3h51m | 7d 15%  4d15h | Opus 5.5 | <branch>`, with colors.
6. **Tell the person** it's set, and that it shows at the bottom of the terminal from the next message in this session, or in any new one.

## Undo

Delete the `statusLine` key from `<config>/settings.json` (or put `settings.json.bak` back), and delete `<config>/statusline.cjs`.
