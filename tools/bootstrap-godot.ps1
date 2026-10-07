# Downloads the pinned official portable editor into this project only.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$version = '4.7.2'
$target = Join-Path $projectRoot ".tools/godot/$version"
$exe = Join-Path $target "Godot_v$version-stable_win64_console.exe"
New-Item -ItemType Directory -Path $target -Force | Out-Null
Set-Content -LiteralPath (Join-Path $target '_sc_') -Value ''
if (Test-Path -LiteralPath $exe) {
    & $exe --version
    exit $LASTEXITCODE
}
New-Item -ItemType Directory -Path $target -Force | Out-Null
Set-Content -LiteralPath (Join-Path $projectRoot '.tools/.gdignore') -Value ''
$filename = "Godot_v$version-stable_win64.exe.zip"
$base = "https://github.com/godotengine/godot-builds/releases/download/$version-stable"
$archive = Join-Path $target $filename
$checksumFile = Join-Path $target 'SHA512-SUMS.txt'
Invoke-WebRequest -Uri "$base/$filename" -OutFile $archive
Invoke-WebRequest -Uri "$base/SHA512-SUMS.txt" -OutFile $checksumFile
$entry = Get-Content -LiteralPath $checksumFile | Where-Object { $_ -match ([regex]::Escape($filename) + '$') } | Select-Object -First 1
if (-not $entry) { throw 'Official checksum was not found.' }
$expected = ($entry -split '\s+')[0]
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash
if ($actual -ne $expected) { throw 'Godot archive checksum mismatch; extraction stopped.' }
Expand-Archive -LiteralPath $archive -DestinationPath $target -Force
& $exe --version
exit $LASTEXITCODE

