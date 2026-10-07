param(
    [ValidateSet('run','editor','test','smoke','import','capture','version')]
    [string]$Action = 'run'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$exe = Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
if ($env:GODOT_BIN) { $exe = $env:GODOT_BIN }
if (-not (Test-Path -LiteralPath $exe)) {
    throw 'Godot not found. Run tools/bootstrap-godot.ps1 or set GODOT_BIN.'
}
if (-not $env:GODOT_BIN) { Set-Content -LiteralPath (Join-Path (Split-Path $exe -Parent) '_sc_') -Value '' }
$logFolder = Join-Path $projectRoot 'output/qa'
New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
$engineArgs = @('--path', $projectRoot, '--log-file', (Join-Path $logFolder "$Action.log"))
switch ($Action) {
    'version' { & $exe --version }
    'editor' { & $exe @engineArgs --editor }
    'test' { & $exe @engineArgs --headless --script res://tests/test_runner.gd }
    'smoke' { & $exe @engineArgs --headless --script res://tests/ui_smoke.gd }
    'import' { & $exe @engineArgs --headless --editor --import }
    'capture' { & $exe @engineArgs -- --capture }
    'run' { & $exe @engineArgs }
}
exit $LASTEXITCODE

