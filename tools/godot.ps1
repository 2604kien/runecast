param(
    [ValidateSet('run','editor','test','smoke','import','capture','version')]
    [string]$Action = 'run',
    [string]$Encounter = '',
    [switch]$Experiment,
    [string]$Scenario = 'effects',
    [string]$Variant = 'control',
    [ValidateRange(0,2147483647)][int]$Seed = 42,
    [ValidateSet('opening','cast','inspect')][string]$CaptureStep = 'opening',
    [string]$CapturePath = 'res://output/qa/foundation-screen.png'
)
$ErrorActionPreference = 'Stop'
if ($PSBoundParameters.ContainsKey('CaptureStep') -and ($Action -ne 'capture' -or -not $Experiment)) {
    throw '-CaptureStep requires -Action capture -Experiment.'
}
if (($Experiment -or $PSBoundParameters.ContainsKey('Scenario') -or $PSBoundParameters.ContainsKey('Variant') -or $PSBoundParameters.ContainsKey('Seed')) -and $Action -notin @('run','capture')) {
    throw 'Experiment options apply only to run or capture.'
}
if (-not $Experiment -and ($PSBoundParameters.ContainsKey('Scenario') -or $PSBoundParameters.ContainsKey('Variant') -or $PSBoundParameters.ContainsKey('Seed'))) {
    throw 'Scenario, Variant and Seed require -Experiment.'
}
if ($Experiment -and $Encounter) { throw '-Experiment and -Encounter are separate launch modes.' }
if ($Encounter -and $Action -notin @('run', 'capture')) {
    throw '-Encounter applies to run or capture. Smoke always exercises both training and development scenes plus invalid startup.'
}
if ($PSBoundParameters.ContainsKey('CapturePath') -and $Action -ne 'capture') {
    throw '-CapturePath applies only to capture.'
}
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
$sceneArgs = @()
if ($Encounter) { $sceneArgs += "--encounter=$Encounter" }
if ($Experiment) { $sceneArgs += @('--experiment', "--scenario=$Scenario", "--variant=$Variant", "--seed=$Seed", "--capture-step=$CaptureStep") }
switch ($Action) {
    'version' { & $exe --version }
    'editor' { & $exe @engineArgs --editor }
    'test' { & $exe @engineArgs --headless --script res://tests/test_runner.gd }
    'smoke' { & $exe @engineArgs --headless --script res://tests/ui_smoke.gd }
    'import' { & $exe @engineArgs --headless --editor --import }
    'capture' { & $exe @engineArgs -- --capture "--capture-path=$CapturePath" @sceneArgs }
    'run' { & $exe @engineArgs -- @sceneArgs }
}
exit $LASTEXITCODE

