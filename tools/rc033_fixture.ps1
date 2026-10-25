param(
    [switch]$AtThreshold,
    [switch]$Narrow,
    [switch]$ReducedMotion
)
$ErrorActionPreference = 'Stop'
$rc033Project = Split-Path -Parent $PSScriptRoot
$rc033Engine = Join-Path $rc033Project '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
$rc033Environment = Join-Path $rc033Project 'output\qa\rc-033\manual-environment'
$rc033OldAppData = $env:APPDATA
$rc033OldLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $rc033Environment 'appdata'
    $env:LOCALAPPDATA = Join-Path $rc033Environment 'localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $rc033Arguments = @('--path', $rc033Project, '--script', 'res://tests/rc033_manual.gd', '--')
    if ($AtThreshold) { $rc033Arguments += '--at-threshold' }
    if ($Narrow) { $rc033Arguments += '--narrow' }
    if ($ReducedMotion) { $rc033Arguments += '--reduced-motion' }
    & $rc033Engine @rc033Arguments
} finally {
    $env:APPDATA = $rc033OldAppData
    $env:LOCALAPPDATA = $rc033OldLocalAppData
}
