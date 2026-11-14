// SessionStart hook of the status-bar plugin: copies the status line script to ~/.claude/statusline.cjs,
// so a statusLine setting (an organization's managed settings, for example) can point at one fixed path:
//   "statusLine": { "type": "command", "command": "node \"$HOME/.claude/statusline.cjs\"" }
// It writes only when the file is missing or different, and never fails the session.
const fs = require('fs');
const os = require('os');
const path = require('path');

try {
  const source = path.join(__dirname, '..', 'scripts', 'statusline.cjs');
  const target = path.join(os.homedir(), '.claude', 'statusline.cjs');
  const script = fs.readFileSync(source);
  let current = null;
  try { current = fs.readFileSync(target); } catch {}
  if (!current || !current.equals(script)) {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, script);
  }
} catch {}
