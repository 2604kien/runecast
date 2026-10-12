param(
    [switch]$ImportOnly,
    [string]$QaDirectory = 'output/qa/rc-014/framing-360',
    [string]$ArtDirectory = 'output/art/rc-014/framing-360'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$qa = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $QaDirectory))
$output = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $ArtDirectory))
$stage = Join-Path $qa 'preview-project'
$exe = Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
if ($env:GODOT_BIN) { $exe = $env:GODOT_BIN }
New-Item -ItemType Directory -Force -Path $qa,$output,$stage,(Join-Path $stage 'assets/enemies'),(Join-Path $stage 'retained') | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'rc014_preview/*') -Destination $stage -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'test_shadeling.gd') -Destination (Join-Path $stage 'test_shadeling.gd') -Force
foreach ($folder in @('icons','fonts','ui')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "assets/$folder") -Destination (Join-Path $stage 'assets') -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/enemies/shadeling') -Destination (Join-Path $stage 'assets/enemies') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'source-assets/pilot/revisions/r006/exports/crypt-background.png') -Destination (Join-Path $stage 'retained/crypt-background.png') -Force
function Invoke-PreviewEngine([string[]]$EngineArguments) {
    $process = Start-Process -FilePath $exe -ArgumentList $EngineArguments -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Godot failed ($($process.ExitCode)); inspect $qa" }
}
$quotedStage = '"' + $stage + '"'
Invoke-PreviewEngine @('--headless','--path',$quotedStage,'--editor','--import','--log-file',('"'+(Join-Path $qa 'godot-import.log')+'"'))
# Only promote this character pack's import recipes. Shared runtime resources are read-only inputs.
foreach ($file in Get-ChildItem (Join-Path $stage 'assets/enemies/shadeling') -Filter '*.png.import' -Recurse -File) {
    $relative = $file.FullName.Substring($stage.Length+1)
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $projectRoot $relative) -Force
}
if (-not $ImportOnly) {
    $report = Join-Path $qa 'godot-render-results.json'
    $started = Get-Date
    Invoke-PreviewEngine @('--path',$quotedStage,'--script','res://runner.gd','--quit-after','3600','--log-file',('"'+(Join-Path $qa 'godot-render.log')+'"'),'--',('"--output='+$output+'"'),('"--report='+$report+'"'))
    if ((Get-Content -LiteralPath (Join-Path $qa 'godot-render.log') -Raw) -match 'SCRIPT ERROR|Parse Error|Failed to load') { throw 'Godot script/resource error; inspect render log.' }
    if (-not (Test-Path -LiteralPath $report)) { throw 'Render report missing.' }
    if ((Get-Item -LiteralPath $report).LastWriteTime -lt $started) { throw 'Render report is stale.' }
    if ((Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).result -ne 'PASS') { throw 'Character checks failed; inspect render report.' }
}
Write-Output 'RC-014 isolated character import/render complete.'
