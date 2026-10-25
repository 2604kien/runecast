param([ValidateSet('Combat','Store','Upgrade')][string]$Mode = 'Store', [switch]$Narrow)
$ErrorActionPreference = 'Stop'
$rc035Project = Split-Path -Parent $PSScriptRoot
$rc035Environment = Join-Path $rc035Project 'output\qa\rc-035\manual-environment'
$rc035OldAppData = $env:APPDATA
$rc035OldLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $rc035Environment 'appdata'
    $env:LOCALAPPDATA = Join-Path $rc035Environment 'localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $rc035Engine = Join-Path $rc035Project '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
    $rc035Arguments = @('--path', $rc035Project, '--script', 'res://tests/rc035_manual.gd', '--', "--mode=$($Mode.ToLowerInvariant())")
    if ($Narrow) { $rc035Arguments += '--narrow' }
    & $rc035Engine @rc035Arguments
} finally {
    $env:APPDATA = $rc035OldAppData
    $env:LOCALAPPDATA = $rc035OldLocalAppData
}
