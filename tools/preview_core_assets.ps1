param([switch]$ImportOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$qa = Join-Path $projectRoot 'output/qa/rc-012'
$stage = Join-Path $qa 'preview-project'
$exe = Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
if ($env:GODOT_BIN) { $exe = $env:GODOT_BIN }
New-Item -ItemType Directory -Force -Path $stage,(Join-Path $stage 'assets'),(Join-Path $stage 'materials') | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'rc012_preview/*') -Destination $stage -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/icons'),(Join-Path $projectRoot 'assets/fonts') -Destination (Join-Path $stage 'assets') -Recurse -Force
foreach ($name in @('board-stone','parchment','amber','navy')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "source-assets/pilot/revisions/r006/ui/materials/$name.png") -Destination (Join-Path $stage 'materials') -Force
}
function Invoke-PreviewEngine([string[]]$EngineArguments) {
    $process = Start-Process -FilePath $exe -ArgumentList $EngineArguments -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Godot failed with code $($process.ExitCode). Inspect logs in $qa" }
}
$quotedStage = '"' + $stage + '"'
$importLog = '"' + (Join-Path $qa 'godot-import.log') + '"'
Invoke-PreviewEngine @('--headless','--path',$quotedStage,'--editor','--import','--log-file',$importLog)
foreach ($file in (Get-ChildItem (Join-Path $stage 'assets/icons') -Filter '*.svg.import' -Recurse -File)) {
    $contents = Get-Content -LiteralPath $file.FullName -Raw
    $contents = $contents -replace 'svg/scale=1\.0','svg/scale=2.0'
    Set-Content -LiteralPath $file.FullName -Value $contents -Encoding utf8 -NoNewline
}
Invoke-PreviewEngine @('--headless','--path',$quotedStage,'--editor','--import','--log-file',$importLog)
# Keep real Godot import recipes beside the runtime exports; no generated .godot cache is promoted.
foreach ($file in (Get-ChildItem (Join-Path $stage 'assets/icons') -Filter '*.svg.import' -Recurse -File)) {
    $relative = $file.FullName.Substring($stage.Length+1)
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $projectRoot $relative) -Force
}
if (-not $ImportOnly) {
    $output = Join-Path $projectRoot 'output/art/rc-012'
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    $renderLog = '"' + (Join-Path $qa 'godot-render.log') + '"'
    $report = Join-Path $qa 'godot-render-results.json'
    Invoke-PreviewEngine @('--path',$quotedStage,'--script','res://runner.gd','--quit-after','600','--log-file',$renderLog,'--',('"--output='+$output+'"'),('"--report='+$report+'"'))
}
Write-Output 'RC-012 isolated Godot imports/previews complete.'
