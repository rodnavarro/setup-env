#!/usr/bin/env node
'use strict';
// Claude Code status line:
//   c 0.0% | 5h 1%  3h51m | 7d 15%  4d15h | Opus 5.5 | master
// Context used, 5-hour and 7-day plan limits with time to reset, model, git branch.
// Everything comes from the JSON Claude Code pipes in on stdin. A segment it hasn't
// sent yet (the limits, before the first reply of a session) is left out.
const { execSync } = require('child_process');
const fs = require('fs');

function readStdinJson() {
  try {
    return JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return null;
  }
}

const data = readStdinJson();

const DIM = '\x1b[90m';
const RST = '\x1b[0m';
const SEP = ` ${DIM}|${RST} `;

// Green under 50%, yellow from 50%, red from 80%.
function pctColor(pct) {
  return pct >= 80 ? '\x1b[31m' : pct >= 50 ? '\x1b[33m' : '\x1b[32m';
}

function pctText(pct) {
  return `${pctColor(pct)}${pct < 1 ? pct.toFixed(1) : Math.round(pct)}%${RST}`;
}

// "3h51m" or "45m" for the 5-hour window, "4d15h" for the 7-day one.
function untilReset(resetsAt, withDays) {
  if (!resetsAt) return '';
  const mins = Math.round((resetsAt * 1000 - Date.now()) / 60_000);
  if (mins <= 0) return '';
  const d = Math.floor(mins / 1440);
  const h = Math.floor((mins % 1440) / 60);
  const m = mins % 60;
  if (withDays && d > 0) return `  ${d}d${h}h`;
  const totalH = Math.floor(mins / 60);
  return totalH > 0 ? `  ${totalH}h${m}m` : `  ${m}m`;
}

function modelLabel() {
  const raw = (data?.model?.display_name || data?.model?.id || '').trim();
  for (const family of ['Opus', 'Sonnet', 'Haiku', 'Fable']) {
    if (new RegExp(family, 'i').test(raw)) {
      const v = raw.match(/(\d[\d.-]*)/);
      return v ? `${family} ${v[1].replace(/-/g, '.')}` : family;
    }
  }
  return raw;
}

function gitBranch() {
  try {
    const cwd = data?.workspace?.current_dir || data?.cwd || process.cwd();
    const branch = execSync(`git --no-optional-locks -C ${JSON.stringify(cwd)} rev-parse --abbrev-ref HEAD`, {
      encoding: 'utf8', timeout: 3_000, stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    return branch && branch !== 'HEAD' ? branch : '';
  } catch {
    return '';
  }
}

const parts = [];

const ctx = data?.context_window?.used_percentage;
if (ctx != null) parts.push(`c ${pctText(ctx)}`);

const five = data?.rate_limits?.five_hour;
if (five?.used_percentage != null) parts.push(`5h ${pctText(five.used_percentage)}${untilReset(five.resets_at, false)}`);

const seven = data?.rate_limits?.seven_day;
if (seven?.used_percentage != null) parts.push(`7d ${pctText(seven.used_percentage)}${untilReset(seven.resets_at, true)}`);

const model = modelLabel();
if (model) parts.push(`\x1b[97m${model}${RST}`);

const branch = gitBranch();
if (branch) parts.push(`\x1b[96m${branch}${RST}`);

process.stdout.write(parts.join(SEP));
