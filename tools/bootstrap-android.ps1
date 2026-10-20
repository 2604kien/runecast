param(
    [string]$JavaSdkPath = '',
    [string]$AndroidSdkPath = '',
    [string]$GodotBin = '',
    [switch]$InitializeDebugSigning,
    [string]$SigningProfile = (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'RuneCast/Android/debug-signing.json')
)
# First-time setup only. Repeat builds use android.ps1. No global PATH changes.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'android-toolchain.json') -Raw | ConvertFrom-Json
$localRoot = Join-Path $projectRoot '.tools/android'
$downloads = Join-Path $localRoot 'downloads'
function Get-VerifiedArchive([string]$Url, [string]$Algorithm, [string]$Expected) {
    $archive = Join-Path $downloads ([Uri]::UnescapeDataString(([Uri]$Url).Segments[-1]))
    if (-not (Test-Path -LiteralPath $archive)) {
        Write-Host "Downloading $([IO.Path]::GetFileName($archive))"
        Invoke-WebRequest -Uri $Url -OutFile $archive
    }
    if ((Get-FileHash -LiteralPath $archive -Algorithm $Algorithm).Hash -ne $Expected) {
        throw "Checksum mismatch: $archive. Remove this incomplete archive before retrying."
    }
    return $archive
}
try {
    New-Item -ItemType Directory -Force -Path $downloads | Out-Null
    if (-not $GodotBin) { $GodotBin = Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' }
    if (-not (Test-Path -LiteralPath $GodotBin)) { throw 'Run tools/bootstrap-godot.ps1 first.' }
    $version = (& $GodotBin --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $version -ne $manifest.engine) { throw "Expected $($manifest.engine); found $version. No engine is upgraded by this helper." }
    $editorRoot = Split-Path $GodotBin -Parent
    if (-not (Test-Path -LiteralPath (Join-Path $editorRoot '_sc_')) -and -not (Test-Path -LiteralPath (Join-Path $editorRoot '_sc_.txt'))) {
        throw 'This setup targets the portable self-contained editor; its _sc_ marker is missing.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $templateRoot = Join-Path $editorRoot "editor_data/export_templates/$($manifest.templates.version)"
    $templateArchive = Get-VerifiedArchive $manifest.templates.url SHA512 $manifest.templates.sha512
    $zip = [IO.Compression.ZipFile]::OpenRead($templateArchive)
    try {
        New-Item -ItemType Directory -Force -Path $templateRoot | Out-Null
        foreach ($name in @('version.txt','android_debug.apk','android_release.apk')) {
            $entry = $zip.GetEntry("templates/$name")
            if (-not $entry) { throw "Official archive lacks $name" }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $templateRoot $name), $true)
        }
    } finally { $zip.Dispose() }
    if ((Get-Content -LiteralPath (Join-Path $templateRoot 'version.txt') -Raw).Trim() -ne $manifest.templates.version) { throw 'Template version mismatch.' }

    if (-not $JavaSdkPath) {
        $JavaSdkPath = Join-Path $localRoot "jdk/$($manifest.jdk.directory)"
        if (-not (Test-Path -LiteralPath (Join-Path $JavaSdkPath 'bin/java.exe'))) {
            $jdkArchive = Get-VerifiedArchive $manifest.jdk.url SHA256 $manifest.jdk.sha256
            Expand-Archive -LiteralPath $jdkArchive -DestinationPath (Join-Path $localRoot 'jdk') -Force
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $JavaSdkPath 'bin/keytool.exe'))) { throw 'JavaSdkPath must identify a JDK with bin/keytool.exe.' }
    if (-not $AndroidSdkPath) {
        $AndroidSdkPath = Join-Path $localRoot 'sdk'
        foreach ($package in $manifest.sdk) {
            $destination = Join-Path $AndroidSdkPath $package.directory
            if (Test-Path -LiteralPath (Join-Path $destination 'source.properties')) { continue }
            $archive = Get-VerifiedArchive $package.url SHA1 $package.sha1
            $stage = Join-Path $localRoot ('stage-' + ($package.package -replace '[;.]', '-'))
            Expand-Archive -LiteralPath $archive -DestinationPath $stage -Force
            $children = @(Get-ChildItem -LiteralPath $stage -Directory)
            if ($children.Count -ne 1) { throw "Unexpected archive structure for $($package.package)." }
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Copy-Item -Path (Join-Path $children[0].FullName '*') -Destination $destination -Recurse -Force
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $AndroidSdkPath 'platform-tools/adb.exe'))) { throw 'AndroidSdkPath lacks platform-tools/adb.exe.' }
    if ($InitializeDebugSigning) {
        $profilePath = [IO.Path]::GetFullPath($SigningProfile)
        if ($profilePath.StartsWith($projectRoot.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Debug signing must be outside the repository.' }
        if (Test-Path -LiteralPath $profilePath) {
            Write-Host 'Existing external signing profile retained.'
        } else {
            $signingDirectory = Split-Path $profilePath -Parent
            New-Item -ItemType Directory -Force -Path $signingDirectory | Out-Null
            $keyPath = Join-Path $signingDirectory 'debug.keystore'
            if (Test-Path -LiteralPath $keyPath) { throw 'Existing key has no profile. Preserve it and supply its credentials explicitly; it will not be replaced.' }
            $bytes = New-Object byte[] 32
            $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
            try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
            $password = [Convert]::ToBase64String($bytes)
            $oldPassword = $env:RUNECAST_DEBUG_KEY_PASSWORD
            try {
                $env:RUNECAST_DEBUG_KEY_PASSWORD = $password
                & (Join-Path $JavaSdkPath 'bin/keytool.exe') -genkeypair -keystore $keyPath -storetype JKS -alias androiddebugkey -storepass:env RUNECAST_DEBUG_KEY_PASSWORD -keypass:env RUNECAST_DEBUG_KEY_PASSWORD -dname 'CN=Android Debug,O=Android,C=US' -keyalg RSA -keysize 2048 -validity 10000 *> $null
                if ($LASTEXITCODE -ne 0) { throw 'Local debug-key generation failed; no credentials were logged.' }
                @{keystore=$keyPath;user='androiddebugkey';password=$password} | ConvertTo-Json | Set-Content -LiteralPath $profilePath -Encoding UTF8
            } finally { $env:RUNECAST_DEBUG_KEY_PASSWORD = $oldPassword; $password = $null }
            Write-Host 'Created local debug signing outside the repository.'
        }
    }
    Write-Host "Godot/templates: $version / $($manifest.templates.version)"
    Write-Host "Java SDK: $JavaSdkPath"
    Write-Host "Android SDK: $AndroidSdkPath"
    Write-Host 'Next: tools/android.ps1 -Action validate, then -Action build.'
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
