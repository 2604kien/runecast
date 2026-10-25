param([int]$Seed = 1, [switch]$Narrow)
$ErrorActionPreference = 'Stop'
$rc034Project = Split-Path -Parent $PSScriptRoot
$rc034Environment = Join-Path $rc034Project 'output\qa\rc-034\manual-environment'
$rc034OldAppData = $env:APPDATA
$rc034OldLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $rc034Environment 'appdata'
    $env:LOCALAPPDATA = Join-Path $rc034Environment 'localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $rc034Engine = Join-Path $rc034Project '.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe'
    $rc034Arguments = @('--path', $rc034Project, '--script', 'res://tests/rc034_manual.gd', '--', "--seed=$Seed")
    if ($Narrow) { $rc034Arguments += '--narrow' }
    & $rc034Engine @rc034Arguments
} finally {
    $env:APPDATA = $rc034OldAppData
    $env:LOCALAPPDATA = $rc034OldLocalAppData
}
