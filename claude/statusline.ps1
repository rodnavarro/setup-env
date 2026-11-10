# Claude Code status line, for Windows machines without Node.js:
#   c 0.0% | 5h 1%  3h51m | 7d 15%  4d15h | Opus 5.5 | main
# Context used, 5-hour and 7-day plan limits with time to reset, model, git branch.
# Everything comes from the JSON Claude Code pipes in on stdin. A segment it hasn't
# sent yet (the limits, before the first reply of a session) is left out.
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { $data = $null }

$E = [char]27
$DIM = "$E[90m"; $RST = "$E[0m"
$SEP = " $DIM|$RST "

function PctText($pct) {
  $c = if ($pct -ge 80) { "$E[31m" } elseif ($pct -ge 50) { "$E[33m" } else { "$E[32m" }
  $t = if ($pct -lt 1) { '{0:0.0}' -f $pct } else { [math]::Round($pct) }
  "$c$t%$RST"
}

# "3h51m" or "45m" for the 5-hour window, "4d15h" for the 7-day one.
function UntilReset($resetsAt, $withDays) {
  if (-not $resetsAt) { return '' }
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $mins = [math]::Round(($resetsAt - $now) / 60)
  if ($mins -le 0) { return '' }
  $d = [math]::Floor($mins / 1440); $h = [math]::Floor(($mins % 1440) / 60); $m = $mins % 60
  if ($withDays -and $d -gt 0) { return "  ${d}d${h}h" }
  $totalH = [math]::Floor($mins / 60)
  if ($totalH -gt 0) { "  ${totalH}h${m}m" } else { "  ${m}m" }
}

function ModelLabel {
  $name = "$($data.model.display_name)"
  if (-not $name) { $name = "$($data.model.id)" }
  foreach ($family in 'Opus', 'Sonnet', 'Haiku', 'Fable') {
    if ($name -match $family) {
      if ($name -match '(\d[\d.-]*)') { return "$family $($Matches[1] -replace '-', '.')" }
      return $family
    }
  }
  $name.Trim()
}

$parts = @()
$ctx = $data.context_window.used_percentage
if ($null -ne $ctx) { $parts += "c $(PctText $ctx)" }
$five = $data.rate_limits.five_hour
if ($null -ne $five.used_percentage) { $parts += "5h $(PctText $five.used_percentage)$(UntilReset $five.resets_at $false)" }
$seven = $data.rate_limits.seven_day
if ($null -ne $seven.used_percentage) { $parts += "7d $(PctText $seven.used_percentage)$(UntilReset $seven.resets_at $true)" }
$model = ModelLabel
if ($model) { $parts += "$E[97m$model$RST" }

$cwd = "$($data.workspace.current_dir)"
if (-not $cwd) { $cwd = (Get-Location).Path }
$branch = git --no-optional-locks -C $cwd rev-parse --abbrev-ref HEAD 2>$null
if ($branch -and $branch -ne 'HEAD') { $parts += "$E[96m$branch$RST" }

[Console]::Out.Write($parts -join $SEP)
