param([switch]$ImportOnly, [ValidatePattern('^$|^[a-z0-9]+(-[a-z0-9]+)*$')][string]$EvidenceName = '', [switch]$MenuOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$qa = Join-Path $projectRoot 'output/qa/rc-013'
if ($EvidenceName) { $qa = Join-Path $qa $EvidenceName }
$stage = Join-Path $qa 'preview-project'
$exe = Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
if ($env:GODOT_BIN) { $exe = $env:GODOT_BIN }
New-Item -ItemType Directory -Force -Path $stage,(Join-Path $stage 'assets'),(Join-Path $stage 'scenes/ui') | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'rc013_preview/*') -Destination $stage -Force
foreach ($folder in @('icons','fonts','ui')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "assets/$folder") -Destination (Join-Path $stage 'assets') -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'scenes/ui/theme') -Destination (Join-Path $stage 'scenes/ui') -Recurse -Force
function Invoke-PreviewEngine([string[]]$EngineArguments) {
    $process = Start-Process -FilePath $exe -ArgumentList $EngineArguments -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Godot failed ($($process.ExitCode)); inspect $qa" }
}
$quotedStage = '"' + $stage + '"'
$importLog = '"' + (Join-Path $qa 'godot-import.log') + '"'
Invoke-PreviewEngine @('--headless','--path',$quotedStage,'--editor','--import','--log-file',$importLog)
# Promote only RC-013 import recipes. Never modify RC-012 icons/font settings.
foreach ($file in (Get-ChildItem (Join-Path $stage 'assets/ui') -Include '*.png.import','*.svg.import' -Recurse -File | Where-Object { -not $EvidenceName })) {
    if ($file.Name -eq 'app_icon.svg.import') { continue }
    $relative = $file.FullName.Substring($stage.Length+1)
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $projectRoot $relative) -Force
}
if (-not $ImportOnly) {
    $output = Join-Path $projectRoot 'output/art/rc-013'
    if ($EvidenceName) { $output = Join-Path $output $EvidenceName }
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    $renderLog = '"' + (Join-Path $qa 'godot-render.log') + '"'
    $report = Join-Path $qa 'godot-render-results.json'
    $started = Get-Date
    $renderArgs = @('--path',$quotedStage,'--script','res://runner.gd','--quit-after','2400','--log-file',$renderLog,'--',('"--output='+$output+'"'),('"--report='+$report+'"'))
    if ($MenuOnly) { $renderArgs += '--menu-only' }
    Invoke-PreviewEngine $renderArgs
    if ((Get-Content -LiteralPath (Join-Path $qa 'godot-render.log') -Raw) -match 'SCRIPT ERROR|Parse Error|Failed to load') { throw 'Godot script/resource error; inspect render log.' }
    if (-not (Test-Path -LiteralPath $report)) { throw 'Render report missing.' }
    if ((Get-Item -LiteralPath $report).LastWriteTime -lt $started) { throw 'Render report is stale.' }
    if ((Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).result -ne 'PASS') { throw 'Theme layout/input checks failed; inspect render report.' }
}
Write-Output 'RC-013 isolated theme import/render complete.'
