// SessionStart hook of the status-bar plugin: copies the status line script into Claude Code's settings
// folder ($CLAUDE_CONFIG_DIR, or ~/.claude), so each alias (claude-work, claude-bba...) keeps its own copy.
// A statusLine setting (an organization's managed settings, for example) finds it the same way:
//   "statusLine": { "type": "command", "command": "node -e \"require(require('path').join(process.env.CLAUDE_CONFIG_DIR||require('os').homedir()+'/.claude','statusline.cjs'))\"" }
// It writes only when the file is missing or different, and never fails the session.
const fs = require('fs');
const os = require('os');
const path = require('path');

try {
  const source = path.join(__dirname, '..', 'scripts', 'statusline.cjs');
  const config = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
  const target = path.join(config, 'statusline.cjs');
  const script = fs.readFileSync(source);
  let current = null;
  try { current = fs.readFileSync(target); } catch {}
  if (!current || !current.equals(script)) {
    fs.mkdirSync(config, { recursive: true });
    fs.writeFileSync(target, script);
  }
} catch {}
