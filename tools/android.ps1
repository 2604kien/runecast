# Local Android development only. Exit codes: 2 setup, 3 export, 4 package,
# 5 device/deployment, 6 diagnostics, 1 unexpected error. Never clears app data.
[CmdletBinding()]
param(
    [ValidateSet('validate','build','inspect','devices','install','launch','diagnostics')]
    [string]$Action = 'validate',
    [string]$GodotBin = '',
    [string]$JavaSdkPath = '',
    [string]$AndroidSdkPath = '',
    [string]$SigningProfile = '',
    [string]$PythonBin = '',
    [string]$Device = '',
    [string]$ApkPath = 'builds/android/RuneCast-debug.apk',
    [string]$LogDirectory = 'output/qa/rc-021'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$projectRoot = Split-Path $PSScriptRoot -Parent
$expectedGodot = '4.7.2.stable.official.ed1daf0bf'
$templateVersion = '4.7.2.stable'
$packageName = 'com.example.runecast'
$script:failureCode = 1
$script:redactions = @()
$savedEnvironment = @{}
foreach ($name in @('JAVA_HOME','ANDROID_HOME','ANDROID_SDK_ROOT','APPDATA','LOCALAPPDATA','GODOT_ANDROID_KEYSTORE_DEBUG_PATH','GODOT_ANDROID_KEYSTORE_DEBUG_USER','GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD')) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

function Resolve-ProjectPath([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $projectRoot $Path }
    return [IO.Path]::GetFullPath($Path)
}

function Protect-Text([string]$Text) {
    foreach ($value in $script:redactions) {
        if ($value) { $Text = $Text.Replace($value, '[local signing value]') }
    }
    return $Text
}

function Save-Json([string]$Name, $Value) {
    $Value | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $logFolder $Name) -Encoding UTF8
}

function Invoke-Checked([string]$File, [string[]]$Arguments, [string]$LogName = '', [switch]$Quiet) {
    # Do not echo command arguments: signing is supplied only through process env.
    if (-not (Get-Command $File -CommandType Application -ErrorAction SilentlyContinue)) { throw "Executable not found: $File" }
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $File @Arguments 2>&1 | ForEach-Object { Protect-Text $_.ToString() })
        $nativeExitCode = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
    if ($LogName) { $output | Set-Content -LiteralPath (Join-Path $logFolder $LogName) -Encoding UTF8 }
    if (-not $Quiet) { foreach ($line in $output) { Write-Host $line } }
    if ($nativeExitCode -ne 0) {
        throw "$(Split-Path $File -Leaf) failed (exit $nativeExitCode). $(if ($LogName) { 'See ' + (Join-Path $logFolder $LogName) })"
    }
    return $output
}

function Require-File([string]$Path, [string]$Message) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw $Message }
}

function Initialize-Sdk {
    if (-not $script:AndroidSdkPath) {
        $scopedSdk = Join-Path $projectRoot '.tools/android/sdk'
        $script:AndroidSdkPath = if (Test-Path -LiteralPath $scopedSdk) { $scopedSdk } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { $scopedSdk }
    }
    $script:AndroidSdkPath = Resolve-ProjectPath $script:AndroidSdkPath
    $script:adb = Join-Path $script:AndroidSdkPath 'platform-tools/adb.exe'
    Require-File $script:adb 'Android platform tools are missing. Run first-time Android setup or pass -AndroidSdkPath containing platform-tools/adb.exe.'
    $env:ANDROID_HOME = $script:AndroidSdkPath
    $env:ANDROID_SDK_ROOT = $script:AndroidSdkPath
}

function Initialize-Java {
    if (-not $script:JavaSdkPath) {
        $scopedJdk = Join-Path $projectRoot '.tools/android/jdk'
        if (Test-Path -LiteralPath (Join-Path $scopedJdk 'bin/java.exe')) { $script:JavaSdkPath = $scopedJdk }
        elseif (Test-Path -LiteralPath $scopedJdk) {
            $candidates = @(Get-ChildItem -LiteralPath $scopedJdk -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin/java.exe') })
            if ($candidates.Count -eq 1) { $script:JavaSdkPath = $candidates[0].FullName }
        }
        if (-not $script:JavaSdkPath -and $env:JAVA_HOME) { $script:JavaSdkPath = $env:JAVA_HOME }
    }
    if (-not $script:JavaSdkPath) { throw 'OpenJDK 17 was not found. Run first-time setup or pass -JavaSdkPath (the JDK directory, not bin/java.exe).' }
    $script:JavaSdkPath = Resolve-ProjectPath $script:JavaSdkPath
    $script:java = Join-Path $script:JavaSdkPath 'bin/java.exe'
    Require-File $script:java 'Java SDK path does not contain bin/java.exe.'
    Require-File (Join-Path $script:JavaSdkPath 'bin/keytool.exe') 'Java SDK path does not contain bin/keytool.exe.'
    $script:javaVersion = (Invoke-Checked $script:java @('-version') 'java-version.txt' -Quiet) -join "`n"
    if ($script:javaVersion -notmatch '(?:openjdk|java) version "17\.') { throw 'This development build requires the documented OpenJDK 17 toolchain. Pass -JavaSdkPath for JDK 17.' }
    $env:JAVA_HOME = $script:JavaSdkPath
}

function Initialize-Signing {
    $names = @('GODOT_ANDROID_KEYSTORE_DEBUG_PATH','GODOT_ANDROID_KEYSTORE_DEBUG_USER','GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD')
    $present = @($names | Where-Object { [Environment]::GetEnvironmentVariable($_, 'Process') })
    if ($present.Count -gt 0 -and $present.Count -ne 3) { throw 'Set all three GODOT_ANDROID_KEYSTORE_DEBUG_PATH, _USER and _PASSWORD variables, or unset them to use the local signing profile.' }
    if ($present.Count -eq 0) {
        if (-not $script:SigningProfile) { $script:SigningProfile = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'RuneCast/Android/debug-signing.json' }
        $profilePath = Resolve-ProjectPath $script:SigningProfile
        if ($profilePath.StartsWith($projectRoot.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'The debug signing profile must be outside the repository.' }
        Require-File $profilePath 'Local debug signing profile is missing. Run first-time setup, pass -SigningProfile, or supply the complete Godot debug-signing environment trio.'
        try { $profile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json } catch { throw 'The local debug signing profile is not valid JSON.' }
        foreach ($property in @('keystore','user','password')) {
            if (-not $profile.PSObject.Properties[$property] -or -not $profile.$property) { throw 'The local signing profile requires nonempty keystore, user and password fields.' }
        }
        $env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = [string]$profile.keystore
        $env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = [string]$profile.user
        $env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = [string]$profile.password
    }
    $script:redactions = @($env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH, $env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH.Replace('\','/'), $env:GODOT_ANDROID_KEYSTORE_DEBUG_USER, $env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD)
    $keyPath = [IO.Path]::GetFullPath($env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH)
    if ($keyPath.StartsWith($projectRoot.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Debug signing material must be outside the repository. Move it to a private local directory and update the signing profile.' }
    Require-File $keyPath 'The configured local debug keystore is missing.'
    $null = Invoke-Checked (Join-Path $script:JavaSdkPath 'bin/keytool.exe') @('-list','-keystore',$keyPath,'-alias',$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER,'-storepass:env','GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD') -Quiet
}

function Set-EditorString([string]$Text, [string]$Name, [string]$Value) {
    $line = $Name + ' = "' + $Value.Replace('\','/').Replace('"','\"') + '"'
    $pattern = '(?m)^' + [regex]::Escape($Name) + '\s*=.*$'
    if ([regex]::IsMatch($Text, $pattern)) { return [regex]::Replace($Text, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $line }) }
    return $Text.TrimEnd() + "`n" + $line + "`n"
}

function Validate-Toolchain {
    $script:failureCode = 2
    Initialize-Sdk
    Initialize-Java
    if (-not $script:GodotBin) { $script:GodotBin = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe' } }
    $script:GodotBin = Resolve-ProjectPath $script:GodotBin
    Require-File $script:GodotBin 'Pinned Godot executable is missing. Run tools/bootstrap-godot.ps1 or pass -GodotBin.'
    $engineVersion = ((Invoke-Checked $script:GodotBin @('--version') 'godot-version.txt' -Quiet) -join '').Trim()
    if ($engineVersion -ne $expectedGodot) { throw "Engine mismatch: expected $expectedGodot, received $engineVersion. Do not mix editor and templates." }
    $engineFolder = Split-Path $script:GodotBin -Parent
    if (-not (Test-Path -LiteralPath (Join-Path $engineFolder '_sc_') -PathType Leaf) -and -not (Test-Path -LiteralPath (Join-Path $engineFolder '_sc_.txt') -PathType Leaf)) { throw 'Godot must use self-contained mode: the selected editor directory requires an _sc_ or _sc_.txt marker.' }
    $script:editorSettings = Join-Path $engineFolder 'editor_data/editor_settings-4.7.tres'
    Require-File $script:editorSettings 'Portable editor settings are missing. Run the pinned editor/import once before Android setup.'
    $templateFolder = Join-Path $engineFolder "editor_data/export_templates/$templateVersion"
    Require-File (Join-Path $templateFolder 'version.txt') "Matching official export templates are missing from the portable editor_data/export_templates/$templateVersion directory."
    if ((Get-Content -LiteralPath (Join-Path $templateFolder 'version.txt') -Raw).Trim() -ne $templateVersion) { throw 'Export template version.txt does not match the pinned engine release.' }
    Require-File (Join-Path $templateFolder 'android_debug.apk') 'The matching template directory does not contain android_debug.apk.'
    $toolchainManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'android-toolchain.json') -Raw | ConvertFrom-Json
    $templateHash = (Get-FileHash -LiteralPath (Join-Path $templateFolder 'android_debug.apk') -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($templateHash -ne $toolchainManifest.templates.android_debug_sha256) { throw 'Android debug template hash does not match the verified official release. Re-run tools/bootstrap-android.ps1 to restore matching templates.' }
    $buildTools = Join-Path $script:AndroidSdkPath 'build-tools/35.0.1'
    foreach ($tool in @('aapt.exe','apksigner.bat','zipalign.exe')) { Require-File (Join-Path $buildTools $tool) "Android build-tools 35.0.1 are incomplete: missing $tool." }
    Require-File (Join-Path $buildTools 'source.properties') 'Android build-tools version metadata is missing.'
    if ((Get-Content -LiteralPath (Join-Path $buildTools 'source.properties') -Raw) -notmatch '(?m)^Pkg.Revision\s*=\s*35\.0\.1\s*$') { throw 'Installed Android build-tools metadata does not match 35.0.1.' }
    Require-File (Join-Path $script:AndroidSdkPath 'platforms/android-35/android.jar') 'Android platform 35 is missing.'
    Require-File (Join-Path $script:AndroidSdkPath 'platforms/android-35/source.properties') 'Android platform version metadata is missing.'
    if ((Get-Content -LiteralPath (Join-Path $script:AndroidSdkPath 'platforms/android-35/source.properties') -Raw) -notmatch '(?m)^AndroidVersion.ApiLevel\s*=\s*35\s*$') { throw 'Installed Android platform metadata does not match API 35.' }
    $adbVersion = (Invoke-Checked $script:adb @('version') 'adb-version.txt' -Quiet) -join "`n"
    if ($adbVersion -notmatch '(?m)^Version (\d+)\.' -or [int]$Matches[1] -lt 35) { throw 'Android platform tools 35 or newer are required.' }
    Initialize-Signing
    $script:toolchain = [ordered]@{
        godot_version = $engineVersion; godot_path = $script:GodotBin
        template_version = $templateVersion; template_path = $templateFolder
        template_sha256 = $templateHash
        editor_settings = $script:editorSettings; java_path = $script:JavaSdkPath; java_version = $script:javaVersion
        android_sdk = $script:AndroidSdkPath; build_tools = '35.0.1'; platform = 35; platform_tools = $adbVersion
        signing = 'external local debug key; credentials omitted'
    }
    Save-Json 'toolchain.json' $script:toolchain
    Write-Host 'Validated pinned Godot/templates, JDK 17, Android SDK 35, build-tools 35.0.1 and external debug signer.'
}

function Inspect-Apk {
    $script:failureCode = 4
    Require-File $apk 'Debug APK is missing. Run -Action build first.'
    $buildTools = Join-Path $script:AndroidSdkPath 'build-tools/35.0.1'
    $badging = (Invoke-Checked (Join-Path $buildTools 'aapt.exe') @('dump','badging',$apk) 'apk-badging.txt' -Quiet) -join "`n"
    if ($badging -notmatch "package: name='$([regex]::Escape($packageName))'") { throw "APK application ID is not $packageName." }
    if ($badging -notmatch 'application-debuggable') { throw 'APK is not marked debuggable.' }
    if ($badging -notmatch "native-code: 'arm64-v8a'\s*(?:\r?\n|$)") { throw 'APK must contain exactly the approved arm64-v8a ABI.' }
    $permissions = Invoke-Checked (Join-Path $buildTools 'aapt.exe') @('dump','permissions',$apk) 'apk-permissions.txt' -Quiet
    if (($permissions -join "`n") -match '(?m)^uses-permission') { throw 'This development preset should request no Android permissions. Inspect apk-permissions.txt before deploying.' }
    $manifest = (Invoke-Checked (Join-Path $buildTools 'aapt.exe') @('dump','xmltree',$apk,'AndroidManifest.xml') 'apk-manifest.txt' -Quiet) -join "`n"
    # Check component-local blocks: a matching attribute on an unrelated activity
    # must not hide a changed game orientation or a missing exported launcher.
    $activities = [regex]::Matches($manifest, '(?ms)^      E: activity \([^\n]*\n.*?(?=^      E: |\z)')
    $gameActivity = @($activities | Where-Object { $_.Value -match 'android:name\([^)]*\)="com\.godot\.game\.GodotApp"' })
    if ($gameActivity.Count -ne 1 -or $gameActivity[0].Value -notmatch 'android:screenOrientation\([^)]*\)=\(type 0x10\)0x1\b') { throw 'APK game activity does not preserve fixed portrait orientation.' }
    $aliases = [regex]::Matches($manifest, '(?ms)^      E: activity-alias \([^\n]*\n.*?(?=^      E: |\z)')
    $launcherAlias = @($aliases | Where-Object { $_.Value -match 'android:name\([^)]*\)="com\.godot\.game\.GodotAppLauncher"' })
    if ($launcherAlias.Count -ne 1) { throw 'APK does not contain the pinned Godot launcher alias.' }
    $launcher = $launcherAlias[0].Value
    if ($launcher -notmatch 'android:exported\([^)]*\)=\(type 0x12\)0x(?:ffffffff|1)\b' -or $launcher -notmatch 'android:targetActivity\([^)]*\)="com\.godot\.game\.GodotApp"' -or $launcher -notmatch '"android\.intent\.action\.MAIN"' -or $launcher -notmatch '"android\.intent\.category\.LAUNCHER"') { throw 'APK launcher alias is not exported with the expected MAIN/LAUNCHER route to GodotApp.' }
    $metadata = [regex]::Matches($manifest, '(?ms)^      E: meta-data \([^\n]*\n.*?(?=^      E: |\z)')
    $renderer = @($metadata | Where-Object { $_.Value -match '"org\.godotengine\.rendering\.method"' })
    if ($renderer.Count -ne 1 -or $renderer[0].Value -notmatch 'android:value\([^)]*\)="gl_compatibility"') { throw 'APK renderer metadata does not preserve GL Compatibility.' }
    $providers = @([regex]::Matches($manifest, '(?ms)^      E: provider \([^\n]*\n.*?(?=^      E: |\z)') | ForEach-Object {
        [ordered]@{ name = [regex]::Match($_.Value, 'android:name\([^)]*\)="([^"]+)"').Groups[1].Value; authority = [regex]::Match($_.Value, 'android:authorities\([^)]*\)="([^"]+)"').Groups[1].Value }
    })
    $duplicateAuthorities = @($providers | Group-Object -Property { $_['authority'] } | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    Save-Json 'apk-manifest-summary.json' ([ordered]@{ orientation = 'portrait'; renderer = 'gl_compatibility'; launcher_component = "$packageName/com.godot.game.GodotAppLauncher"; providers = $providers; duplicate_provider_authorities = $duplicateAuthorities; provider_note = 'Pinned Godot exporter rewrites provider authorities. Duplicate registration is an upstream artifact; actual installation and startup still require device observation.' })
    $certificate = (Invoke-Checked (Join-Path $buildTools 'apksigner.bat') @('verify','--verbose','--print-certs',$apk) 'apk-signature.txt' -Quiet) -join "`n"
    if ($certificate -notmatch 'CN=Android Debug') { throw 'APK is not signed with the expected local Android Debug identity.' }
    $null = Invoke-Checked (Join-Path $buildTools 'zipalign.exe') @('-c','-P','16','-v','4',$apk) 'apk-alignment.txt' -Quiet
    $versionCode = [regex]::Match($badging, "versionCode='([^']+)'").Groups[1].Value
    $versionName = [regex]::Match($badging, "versionName='([^']+)'").Groups[1].Value
    $minSdk = [regex]::Match($badging, "(?m)^sdkVersion:'(\d+)'").Groups[1].Value
    $targetSdk = [regex]::Match($badging, "(?m)^targetSdkVersion:'(\d+)'").Groups[1].Value
    if (-not $versionCode -or -not $versionName -or -not $minSdk -or -not $targetSdk) { throw 'APK manifest version or SDK metadata could not be read. Inspect apk-badging.txt.' }
    return [ordered]@{ path = $apk; bytes = (Get-Item -LiteralPath $apk).Length; sha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant(); package = $packageName; version_code = [int]$versionCode; version_name = $versionName; min_sdk = [int]$minSdk; target_sdk = [int]$targetSdk; abi = 'arm64-v8a'; debug_signature_verified = $true; requested_permissions = @() }
}

function Require-Device {
    $script:failureCode = 5
    if (-not $Device) { throw 'Pass -Device SERIAL explicitly. Use -Action devices to list connected devices; unlock the phone and authorize USB debugging if needed.' }
    if ($Device -notmatch '^[A-Za-z0-9._:-]+$') { throw 'Device serial contains unsupported characters.' }
    $deviceLines = Invoke-Checked $script:adb @('devices','-l') 'devices.txt' -Quiet
    $selected = @($deviceLines | Where-Object { $_ -match ('^' + [regex]::Escape($Device) + '\s') })
    if ($selected.Count -ne 1 -or $selected[0] -notmatch ('^' + [regex]::Escape($Device) + '\s+device\s')) { throw 'Selected device is absent, offline or unauthorized. Connect it, unlock it and accept its USB debugging prompt, then retry.' }
}

function Invoke-Adb([string[]]$Arguments, [string]$LogName = '', [switch]$Quiet) {
    return Invoke-Checked $script:adb (@('-s',$Device) + $Arguments) $LogName -Quiet:$Quiet
}

function Get-AppPids {
    try { $value = ((Invoke-Adb @('shell','pidof',$packageName) -Quiet) -join ' ').Trim() }
    catch { return @() }
    if ($value -match '^\d+(?:\s+\d+)*$') { return @($value -split '\s+' | Select-Object -Unique) }
    return @()
}

function Get-AppUid {
    $packages = (Invoke-Adb @('shell','cmd','package','list','packages','--user','current','-U',$packageName) -Quiet) -join "`n"
    if ($packages -notmatch ('(?m)^package:' + [regex]::Escape($packageName) + '\s+uid:(\d+)\s*$')) { throw 'Rune Cast is not installed for the current Android user; app-scoped logs cannot be collected.' }
    return $Matches[1]
}

function Get-LaunchAssessment([string]$Result, [string[]]$AppPids) {
    $reportedActivity = [regex]::Match($Result, '(?m)^Activity:\s*(\S+)').Groups[1].Value
    $reasons = @()
    if ($Result -notmatch '(?m)^Status:\s*ok\s*$' -or $Result -match '(?m)^Error:') { $reasons += 'Activity manager did not report Status: ok.' }
    if ($reportedActivity -notmatch ('^' + [regex]::Escape($packageName) + '/[A-Za-z0-9._]+$')) { $reasons += 'Activity manager returned an activity outside Rune Cast or no activity.' }
    if (@($AppPids).Count -eq 0) { $reasons += 'Rune Cast had no live main-process PID after the startup observation.' }
    return [ordered]@{ passed = ($reasons.Count -eq 0); reported_activity = $reportedActivity; app_pids = @($AppPids); observation_seconds = 2; reasons = $reasons }
}

function Get-RecentAppExits([string]$Dump, [string]$AppUid, [DateTimeOffset]$DeviceTime) {
    $records = @()
    foreach ($block in [regex]::Matches($Dump, '(?ms)^\s*ApplicationExitInfo[^\r\n]*:\s*\r?\n.*?(?=^\s*ApplicationExitInfo[^\r\n]*:|\z)')) {
        $process = [regex]::Match($block.Value, '(?m)^\s*process=([^\r\n]+)').Groups[1].Value.Trim()
        $owner = [regex]::Match($block.Value, '(?m)^\s*packageUid=(\d+)').Groups[1].Value
        $appProcessId = [regex]::Match($block.Value, '(?m)^\s*pid=(\d+)').Groups[1].Value
        $timestamp = [regex]::Match($block.Value, '(?m)^\s*timestamp=([^\r\n]+)').Groups[1].Value.Trim()
        if ($process -ne $packageName -or $owner -ne $AppUid -or -not $appProcessId) { continue }
        $parsed = [DateTime]::MinValue
        if (-not [DateTime]::TryParseExact($timestamp, 'yyyy-MM-dd HH:mm:ss.fff', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) { continue }
        $exitedAt = [DateTimeOffset]::new($parsed, $DeviceTime.Offset)
        if ($exitedAt -gt $DeviceTime.AddSeconds(2) -or $exitedAt -lt $DeviceTime.AddMinutes(-15)) { continue }
        $records += [pscustomobject]@{ app_pid = $appProcessId; exited_at = $exitedAt; exit_epoch_seconds = $exitedAt.ToUnixTimeMilliseconds() / 1000.0 }
    }
    return @($records | Sort-Object exited_at -Descending | Select-Object -First 3)
}

function Select-ExitLogWindow([string[]]$Lines, [double]$ExitEpochSeconds) {
    # Historical PIDs can be reused. Retain only the five minutes ending at the
    # recorded app exit, never messages emitted after that process died.
    foreach ($line in $Lines) {
        if ($line -match '^\s*(\d{10}(?:\.\d+)?)\s') {
            $epoch = [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture)
            if ($epoch -ge ($ExitEpochSeconds - 300) -and $epoch -le $ExitEpochSeconds) { $line }
        }
    }
}

function Save-AppLogs([string]$AppUid, [string[]]$AppPids) {
    $help = (Invoke-Adb @('logcat','--help') 'logcat-help.txt' -Quiet) -join "`n"
    $summary = [ordered]@{ app_uid = $AppUid; current_app_pids = @($AppPids); filter = ''; historical_exits = @(); files = @(); maximum_lines_per_query = 2000 }
    if ($help -match '(?m)--uid(?:[=\s,]|$)') {
        $null = Invoke-Adb @('logcat','-d',"--uid=$AppUid",'-v','threadtime','-t','2000') 'app-logcat.txt' -Quiet
        $summary.filter = 'uid'; $summary.files = @('app-logcat.txt')
        return $summary
    }
    if ($help -notmatch '(?m)--pid(?:[=\s,]|$)') { throw 'Device logcat supports neither UID nor PID filtering. No unfiltered logs were collected.' }
    $combined = @()
    if (@($AppPids).Count -gt 0) {
        $summary.filter = 'current_pid'
        foreach ($appProcessId in $AppPids) {
            if ($appProcessId -notmatch '^\d+$') { throw 'Invalid app PID; no logs were collected.' }
            $name = "app-logcat-pid$appProcessId.txt"
            $lines = @(Invoke-Adb @('logcat','-d',"--pid=$appProcessId",'-v','threadtime','-t','2000') $name -Quiet)
            $summary.files += $name
            $combined += @("=== Current Rune Cast PID $appProcessId ===") + $lines
        }
    } else {
        $summary.filter = 'recent_exit_pid_time_bounded'
        $exitInfo = (Invoke-Adb @('shell','dumpsys','activity','exit-info',$packageName) 'app-exit-info.txt' -Quiet) -join "`n"
        $clockText = ((Invoke-Adb @('shell','date','+%Y-%m-%dT%H:%M:%S%z') -Quiet) -join '').Trim()
        $deviceTime = [DateTimeOffset]::MinValue
        if (-not [DateTimeOffset]::TryParse($clockText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$deviceTime)) { throw 'Cannot establish the device clock for historical PID filtering. No historical logs were collected.' }
        $exits = @(Get-RecentAppExits $exitInfo $AppUid $deviceTime)
        $summary.historical_exits = $exits
        foreach ($entry in $exits) {
            $name = "app-logcat-exited-pid$($entry.app_pid).txt"
            $lines = @(Invoke-Adb @('logcat','-d',"--pid=$($entry.app_pid)",'-v','epoch','-t','2000') -Quiet)
            $retained = @(Select-ExitLogWindow $lines $entry.exit_epoch_seconds)
            $retained | Set-Content -LiteralPath (Join-Path $logFolder $name) -Encoding UTF8
            $summary.files += $name
            $combined += @("=== Rune Cast PID $($entry.app_pid), five minutes ending $($entry.exited_at.ToString('o')) ===") + $retained
        }
        if ($exits.Count -eq 0) { $combined = @('No live app PID or exact-process/exact-UID exit within the last 15 device-clock minutes; no logcat messages collected.') }
    }
    $combined | Set-Content -LiteralPath (Join-Path $logFolder 'app-logcat.txt') -Encoding UTF8
    $summary.files += 'app-logcat.txt'
    return $summary
}

try {
    $logFolder = Resolve-ProjectPath $LogDirectory
    $apk = Resolve-ProjectPath $ApkPath
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
    if ($Device -and $Action -notin @('install','launch','diagnostics')) { throw '-Device applies to install, launch or diagnostics.' }
    if ($Action -in @('validate','build')) { Validate-Toolchain }
    else { $script:failureCode = 2; Initialize-Sdk }
    switch ($Action) {
        'validate' { }
        'build' {
            if (-not $PythonBin) {
                $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
                if ($pythonCommand -and $pythonCommand.Source -notmatch 'Microsoft[\\/]WindowsApps') { $PythonBin = $pythonCommand.Source }
            }
            if (-not $PythonBin) { throw 'Package audit requires Python 3. Pass -PythonBin pointing to a working Python 3 executable.' }
            $null = Invoke-Checked $PythonBin @('--version') 'python-version.txt' -Quiet
            # Change only local portable settings; no signing credentials in source/config.
            $settings = [IO.File]::ReadAllText($script:editorSettings)
            $settings = Set-EditorString $settings 'export/android/java_sdk_path' $script:JavaSdkPath
            $settings = Set-EditorString $settings 'export/android/android_sdk_path' $script:AndroidSdkPath
            $settings = Set-EditorString $settings 'export/android/debug_keystore' $env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH
            $settings = Set-EditorString $settings 'export/android/debug_keystore_user' ''
            $settings = Set-EditorString $settings 'export/android/debug_keystore_pass' ''
            [IO.File]::WriteAllText($script:editorSettings, $settings, (New-Object Text.UTF8Encoding $false))
            New-Item -ItemType Directory -Path (Split-Path $apk -Parent) -Force | Out-Null
            $buildUserRoot = Join-Path $logFolder 'build-user-data'
            New-Item -ItemType Directory -Path $buildUserRoot -Force | Out-Null
            $env:APPDATA = $buildUserRoot
            $env:LOCALAPPDATA = $buildUserRoot
            $script:failureCode = 3
            $null = Invoke-Checked $script:GodotBin @('--headless','--path',$projectRoot,'--editor','--import','--log-file',(Join-Path $logFolder 'import-engine.log')) 'import-console.log' -Quiet
            $exportStarted = [DateTime]::UtcNow
            $null = Invoke-Checked $script:GodotBin @('--headless','--path',$projectRoot,'--export-debug','Android',$apk,'--log-file',(Join-Path $logFolder 'export-engine.log')) 'export-console.log' -Quiet
            Require-File $apk 'Godot did not create the requested APK.'
            if ((Get-Item -LiteralPath $apk).LastWriteTimeUtc -lt $exportStarted.AddSeconds(-2)) { throw 'APK was not updated by this export. A stale artifact cannot count as a successful build.' }
            $apkInfo = Inspect-Apk
            $resourcePack = Join-Path $logFolder 'apk-resources.zip'
            $null = Invoke-Checked $PythonBin @((Join-Path $PSScriptRoot 'verify_android_package.py'),$apk,'--project-root',$projectRoot,'--report',(Join-Path $logFolder 'package-contents.json'),'--resource-pack',$resourcePack) 'package-audit-console.txt' -Quiet
            $probeRoot = Join-Path $logFolder ('probe-empty-' + [Guid]::NewGuid().ToString('N'))
            $probeUserRoot = Join-Path $logFolder 'probe-user-data'
            New-Item -ItemType Directory -Path $probeRoot,$probeUserRoot -Force | Out-Null
            # Isolate both filesystem fallback and user settings. This is desktop
            # decoding of actual APK bytes, never a claim of device acceptance.
            $env:APPDATA = $probeUserRoot
            $env:LOCALAPPDATA = $probeUserRoot
            $null = Invoke-Checked $script:GodotBin @('--headless','--path',$probeRoot,'--main-pack',$resourcePack,'--script',(Join-Path $PSScriptRoot 'verify_android_resources.gd'),'--log-file',(Join-Path $logFolder 'apk-resource-probe.log')) 'apk-resource-probe-console.txt' -Quiet
            Save-Json 'build.json' ([ordered]@{ built_at_utc = [DateTime]::UtcNow.ToString('o'); mode = 'debug'; apk = $apkInfo; toolchain = $script:toolchain; export_command = @($script:GodotBin,'--headless','--path',$projectRoot,'--export-debug','Android',$apk); package_audit = 'package-contents.json'; desktop_apk_decode_probe = 'apk-resource-probe.log' })
            Write-Host "Debug APK verified: $apk ($($apkInfo.bytes) bytes; SHA-256 $($apkInfo.sha256))."
        }
        'devices' { $script:failureCode = 5; $null = Invoke-Checked $script:adb @('devices','-l') 'devices.txt' }
        'inspect' {
            Initialize-Java
            $apkInfo = Inspect-Apk
            Save-Json 'apk-metadata.json' $apkInfo
            Write-Host 'APK identity, manifest, permissions, debug signature and alignment passed. Resource-content audit is performed by -Action build.'
        }
        'install' {
            Require-Device
            Initialize-Java
            $apkInfo = Inspect-Apk
            $script:failureCode = 5
            try { $null = Invoke-Adb @('install','-r',$apk) 'install.txt' }
            catch { throw 'APK installation failed; existing app data was preserved. Check install.txt for a signing/version conflict. No uninstall, clear-data or downgrade fallback was attempted.' }
            Save-Json 'install.json' ([ordered]@{ installed_at_utc = [DateTime]::UtcNow.ToString('o'); device = $Device; apk = $apkInfo; command = @($script:adb,'-s',$Device,'install','-r',$apk) })
        }
        'launch' {
            Require-Device
            $resolved = Invoke-Adb @('shell','cmd','package','resolve-activity','--brief','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER',$packageName) 'resolve-activity.txt' -Quiet
            $component = @($resolved | Where-Object { $_ -match ('^' + [regex]::Escape($packageName) + '/[A-Za-z0-9._]+$') })
            if ($component.Count -ne 1) { throw 'Installed Rune Cast launcher activity could not be resolved. Install the verified APK first.' }
            $result = Invoke-Adb @('shell','am','start','-W','-n',$component[0]) 'launch.txt'
            Start-Sleep -Seconds 2
            $appPids = @(Get-AppPids)
            $assessment = Get-LaunchAssessment ($result -join "`n") $appPids
            if (-not $assessment.passed) {
                try { $assessment['diagnostics'] = Save-AppLogs (Get-AppUid) $appPids }
                catch { $assessment['diagnostic_error'] = $_.Exception.Message }
            }
            Save-Json 'launch-verification.json' $assessment
            if (-not $assessment.passed) { throw 'Rune Cast launch verification failed: the expected activity and live app process were not both present. See launch.txt, launch-verification.json and any captured app logs.' }
            Write-Host 'Rune Cast activity and live process verified after two seconds. Continued play/lifecycle still requires observation.'
        }
        'diagnostics' {
            Require-Device
            $script:failureCode = 6
            $info = [ordered]@{ captured_at_utc = [DateTime]::UtcNow.ToString('o'); serial = $Device }
            foreach ($property in @('ro.product.manufacturer','ro.product.model','ro.build.version.release','ro.build.version.sdk','ro.product.cpu.abilist','ro.kernel.qemu','ro.opengles.version','ro.hardware.egl','ro.hardware.vulkan')) {
                $info[$property] = (Invoke-Adb @('shell','getprop',$property) -Quiet) -join ''
            }
            $info['device_classification'] = if ($Device -like 'emulator-*' -or $info['ro.kernel.qemu'] -eq '1') { 'emulator' } else { 'physical_candidate' }
            $info['classification_note'] = 'Inferred from adb serial and ro.kernel.qemu only. Confirm physical hardware directly before acceptance.'
            $info['screen_size'] = (Invoke-Adb @('shell','wm','size') -Quiet) -join "`n"
            $info['screen_density'] = (Invoke-Adb @('shell','wm','density') -Quiet) -join "`n"
            $info['navigation_mode_raw'] = (Invoke-Adb @('shell','settings','get','secure','navigation_mode') -Quiet) -join ''
            $appUid = Get-AppUid
            $info['app_uid'] = $appUid
            $appPids = @(Get-AppPids)
            $info['app_pids'] = $appPids
            $null = Invoke-Adb @('shell','dumpsys','package',$packageName) 'app-package.txt' -Quiet
            $info['log_collection'] = Save-AppLogs $appUid $appPids
            Save-Json 'device.json' $info
            Write-Host "Saved selected-device metadata and app-scoped Rune Cast logs to $logFolder."
        }
    }
    exit 0
} catch {
    [Console]::Error.WriteLine((Protect-Text $_.Exception.Message))
    exit $script:failureCode
} finally {
    # Godot writes its own logs. Scrub signing values even on failed exports.
    if (Get-Variable logFolder -ErrorAction SilentlyContinue) {
        foreach ($name in @('import-engine.log','export-engine.log')) {
            $engineLog = Join-Path $logFolder $name
            if (Test-Path -LiteralPath $engineLog) {
                $content = [IO.File]::ReadAllText($engineLog)
                [IO.File]::WriteAllText($engineLog, (Protect-Text $content), (New-Object Text.UTF8Encoding $false))
            }
        }
    }
    foreach ($name in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process') }
}
