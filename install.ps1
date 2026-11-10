# skills for Windows: a multi-agent Claude Code workspace in a few minutes.
#
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rodnavarro/skills/main/install.ps1 | iex"
#
# What it does, each step skipped when it's already done:
#   1. Installs Claude Code and herdr, if they're missing.
#   2. Sets herdr's theme to catppuccin (only when you haven't picked one).
#   3. Adds the status line to Claude Code: c 25% | 5h 17%  3h51m | 7d 21%  2d2h | Opus 5.5 | main
#   4. Creates the herdr workspace "main" with two tabs, "coordinator" and "researcher",
#      each starting Claude Code in its own folder under ~\agents with its role in CLAUDE.md.
#
# Nothing is deleted. Files it changes are backed up next to themselves first (*.bak-<date>).
# SETUP_ENV_SESSION=<name> uses a named herdr session instead of the default one, and
# SETUP_ENV_AGENTS_DIR another folder (default: the agents folder in your home) for the agents' folders.
$ErrorActionPreference = 'Stop'
$Base = 'https://raw.githubusercontent.com/rodnavarro/skills/main'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Say($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Note($msg) { Write-Host "    $msg" }

# A file of this repo: from the clone when run from one, otherwise from GitHub.
function Asset($rel) {
  if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot $rel))) {
    return [IO.File]::ReadAllText((Join-Path $PSScriptRoot $rel))
  }
  return (Invoke-WebRequest -UseBasicParsing "$Base/$($rel -replace '\\', '/')").Content
}

function WriteText($path, $text) {
  New-Item -ItemType Directory -Force (Split-Path $path) | Out-Null
  [IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding $false))
}

function Backup($path) {
  if (Test-Path $path) { Copy-Item $path "$path.bak-$Stamp" }
}

function AddToPath($dir) {
  if ((Test-Path $dir) -and -not (($env:Path -split ';') -contains $dir)) { $env:Path = "$dir;$env:Path" }
}

# --- 1. Claude Code and herdr ---------------------------------------------------------------
AddToPath (Join-Path $HOME '.local\bin')
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Say "Claude Code is installed"
} else {
  Say "Installing Claude Code"
  Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
  AddToPath (Join-Path $HOME '.local\bin')
}

function FindHerdr {
  $cmd = Get-Command herdr -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $exe = Get-ChildItem (Join-Path $HOME '.herdr') -Recurse -Filter herdr.exe -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($exe) { return $exe.FullName }
  return $null
}
$Herdr = FindHerdr
if ($Herdr) {
  Say "herdr is installed"
} else {
  Say "Installing herdr"
  Invoke-RestMethod https://herdr.dev/install.ps1 | Invoke-Expression
  $Herdr = FindHerdr
  if (-not $Herdr) { throw "herdr didn't install. See https://herdr.dev/tui/docs/install/" }
}
$Session = @()
if ($env:SETUP_ENV_SESSION) { $Session = @('--session', $env:SETUP_ENV_SESSION) }
function Invoke-Herdr { & $Herdr @Session @args }

# --- 2. herdr theme ---------------------------------------------------------------------------
$herdrConfig = Join-Path $env:APPDATA 'herdr\config.toml'
if (-not (Test-Path $herdrConfig)) {
  Say "herdr theme: catppuccin"
  WriteText $herdrConfig (Asset 'herdr\config.toml')
} elseif ((Get-Content $herdrConfig -Raw) -notmatch '(?m)^\s*\[theme\]') {
  Say "herdr theme: catppuccin"
  Backup $herdrConfig
  Add-Content $herdrConfig "`n[theme]`nname = `"catppuccin`"`nauto_switch = false`n"
} else {
  Say "herdr already has a theme; left as it is"
}

# --- 3. Claude Code status line ---------------------------------------------------------------
$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
New-Item -ItemType Directory -Force $claudeDir | Out-Null
if (Get-Command node -ErrorAction SilentlyContinue) {
  $script = Join-Path $claudeDir 'statusline.cjs'
  WriteText $script (Asset 'skills\set-status-bar\scripts\statusline.cjs')
  $command = "node `"$($script -replace '\\', '/')`""
} else {
  $script = Join-Path $claudeDir 'statusline.ps1'
  WriteText $script (Asset 'skills\set-status-bar\scripts\statusline.ps1')
  $command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$($script -replace '\\', '/')`""
}
$settingsPath = Join-Path $claudeDir 'settings.json'
$settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { $null }
if (-not $settings) { $settings = New-Object PSObject }
$statusLine = [pscustomobject]@{ type = 'command'; command = $command }
if ($settings.statusLine -and $settings.statusLine.command -eq $command) {
  Say "Status line is set"
} else {
  Say "Status line: context, 5h and 7d limits, model, branch"
  if ($settings.statusLine) { Note "Replacing your previous status line; it's kept in settings.json.bak-$Stamp" }
  Backup $settingsPath
  $settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
  WriteText $settingsPath ($settings | ConvertTo-Json -Depth 64)
}

# --- 4. The workspace: main, with a coordinator and a researcher --------------------------------
$agents = if ($env:SETUP_ENV_AGENTS_DIR) { $env:SETUP_ENV_AGENTS_DIR } else { Join-Path $HOME 'agents' }
foreach ($role in 'coordinator', 'researcher') {
  $md = Join-Path $agents "$role\CLAUDE.md"
  if (-not (Test-Path $md)) { WriteText $md (Asset "roles\$role.md") }
}

function Api { $out = Invoke-Herdr @args 2>&1 | Out-String; try { $out | ConvertFrom-Json } catch { throw "herdr $($args -join ' '): $out" } }

if (-not ((Invoke-Herdr status server 2>&1 | Out-String) -match 'status: running')) {
  Say "Starting the herdr server"
  Start-Process -FilePath $Herdr -ArgumentList ($Session + @('server')) -WindowStyle Hidden
  foreach ($i in 1..20) { Start-Sleep -Milliseconds 500; if ((Invoke-Herdr status server 2>&1 | Out-String) -match 'status: running') { break } }
}

$ws = (Api workspace list).result.workspaces | Where-Object { $_.label -eq 'main' } | Select-Object -First 1
if ($ws) {
  Say "Workspace main exists"
  $wsId = $ws.workspace_id
} else {
  Say "Creating the workspace main"
  $created = (Api workspace create --label main --cwd (Join-Path $agents 'coordinator') --no-focus).result
  $wsId = $created.workspace.workspace_id
  Api tab rename $created.tab.tab_id coordinator | Out-Null
  Api pane run $created.root_pane.pane_id claude | Out-Null
}

$tabs = (Api tab list --workspace $wsId).result.tabs
foreach ($role in 'coordinator', 'researcher') {
  if ($tabs | Where-Object { $_.label -eq $role }) { continue }
  Say "Adding the tab $role"
  $tab = (Api tab create --workspace $wsId --label $role --cwd (Join-Path $agents $role)).result
  Api pane run $tab.root_pane.pane_id claude | Out-Null
}

Say "Done. Open it with: herdr$(if ($env:SETUP_ENV_SESSION) { " session attach $env:SETUP_ENV_SESSION" })"
Note "The first time, each tab asks whether you trust its folder: choose Yes."
Note "Then talk to the coordinator; it hands research to the researcher."
