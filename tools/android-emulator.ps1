# Scoped Windows Android emulator for RC-021. No global PATH changes, device
# data resets, host feature changes, snapshots, or physical-device acceptance.
<##
.SYNOPSIS
Set up and run the pinned RuneCast Android emulator.
.EXAMPLE
.\tools\android-emulator.ps1 -Action setup
.EXAMPLE
.\tools\android-emulator.ps1 -Action start
.EXAMPLE
.\tools\android-emulator.ps1 -Action status
.EXAMPLE
.\tools\android-emulator.ps1 -Action stop
.NOTES
The default is headless with host graphics. Use -Visible on
start for an emulator window. Dynamic GLES version detection is enabled because
this application requires GLES 3; the emulator's default feature flag caps GLES 2.
API 36 Google APIs x86_64 provides ARM64 translation for the existing arm64 APK.
Emulator coverage supplements, and does not complete, physical-device acceptance.
Requires the platform-tools installed by tools/bootstrap-android.ps1 and usable
Windows virtualization acceleration. This helper never changes Windows features.
Official packages and published SHA-1 checksums are pinned below.
##>
[CmdletBinding()]
param(
    [ValidateSet('setup','start','status','stop')]
    [string]$Action = 'status',
    [ValidateSet('auto','host','software','swiftshader')]
    [string]$Gpu = 'host',
    [switch]$Visible,
    [switch]$NoWait,
    [ValidateRange(30,600)]
    [int]$BootTimeoutSeconds = 300
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$projectRoot = Split-Path $PSScriptRoot -Parent
$localRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '.tools/android'))
$sdkRoot = Join-Path $localRoot 'sdk'
$avdRoot = Join-Path $localRoot 'avd'
$avdName = 'RuneCast_API36'
$avdPath = Join-Path $avdRoot "$avdName.avd"
$avdConfig = Join-Path $avdPath 'config.ini'
$avdLocator = Join-Path $avdRoot "$avdName.ini"
$imageRoot = Join-Path $sdkRoot 'system-images/android-36/google_apis/x86_64'
$emulator = Join-Path $sdkRoot 'emulator/emulator.exe'
$adb = Join-Path $sdkRoot 'platform-tools/adb.exe'
$deviceSerial = 'emulator-5554'
$logRoot = Join-Path $projectRoot 'output/qa/rc-021/emulator'
$packages = @(
    @{
        Name = 'emulator'; Directory = 'emulator'; ArchiveDirectory = 'emulator'
        Url = 'https://dl.google.com/android/repository/emulator-windows_x64-16428233.zip'
        Sha1 = '488ed747e82de7e9bb5247becd1ac043c7e5e85d'
        RequiredFile = 'emulator.exe'; VersionPattern = '(?m)^Pkg.Revision\s*=\s*37\.2\.12\s*$'
    },
    @{
        Name = 'Android 16 Google APIs x86_64'; Directory = 'system-images/android-36/google_apis/x86_64'; ArchiveDirectory = 'x86_64'
        Url = 'https://dl.google.com/android/repository/sys-img/google_apis/x86_64-36_r07.zip'
        Sha1 = 'c6bf44bdcd885bb902b4ba752d111a073ad7a817'
        RequiredFile = 'system.img'; VersionPattern = '(?m)^Pkg.Revision\s*=\s*7\s*$'
    }
)
$savedEnvironment = @{}
foreach ($name in @('ANDROID_HOME','ANDROID_SDK_ROOT','ANDROID_AVD_HOME')) {
    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

function Assert-LocalPath([string]$Path) {
    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not $resolved.StartsWith($localRoot.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the scoped Android directory: $resolved"
    }
    return $resolved
}

function Save-Json([string]$Name, $Value) {
    $Value | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $logRoot $Name) -Encoding UTF8
}

function Invoke-Native([string]$File, [string[]]$Arguments, [switch]$AllowFailure) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $lines = @(& $File @Arguments 2>&1 | ForEach-Object { $_.ToString() })
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
    $result = [pscustomobject]@{ ExitCode = $code; Output = ($lines -join "`n") }
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "$(Split-Path $File -Leaf) failed (exit $code): $($result.Output)"
    }
    return $result
}

function Assert-Packages {
    foreach ($package in $packages) {
        $destination = Join-Path $sdkRoot $package.Directory
        $metadata = Join-Path $destination 'source.properties'
        if (-not (Test-Path -LiteralPath $metadata -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $destination $package.RequiredFile) -PathType Leaf)) {
            throw "Missing/incomplete $($package.Name). Run tools/android-emulator.ps1 -Action setup."
        }
        if ((Get-Content -LiteralPath $metadata -Raw) -notmatch $package.VersionPattern) {
            throw "$($package.Name) has a different revision. Preserve the existing directory and resolve the mismatch before setup."
        }
    }
    $imageMetadata = Get-Content -LiteralPath (Join-Path $imageRoot 'source.properties') -Raw
    if ($imageMetadata -notmatch '(?m)^AndroidVersion.ApiLevel\s*=\s*36\s*$' -or
        $imageMetadata -notmatch '(?m)^SystemImage.Abi\s*=\s*x86_64\s*$' -or
        $imageMetadata -notmatch '(?m)^SystemImage.TagId\s*=\s*google_apis\s*$') {
        throw 'The system image must be Android API 36 Google APIs x86_64 revision 7.'
    }
}

function Install-Packages {
    $downloads = Join-Path $localRoot 'downloads'
    New-Item -ItemType Directory -Force -Path $downloads | Out-Null
    foreach ($package in $packages) {
        $destination = Assert-LocalPath (Join-Path $sdkRoot $package.Directory)
        # Preserve every existing installation. Validation below reports mismatches.
        if (Test-Path -LiteralPath $destination) { continue }
        $archive = Assert-LocalPath (Join-Path $downloads ([Uri]$package.Url).Segments[-1])
        if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) {
            $partial = Assert-LocalPath ($archive + '.download')
            if (Test-Path -LiteralPath $partial) { throw "An incomplete download exists: $partial. Preserve or remove it before retrying setup." }
            Write-Host "Downloading $($package.Name) from dl.google.com..."
            Invoke-WebRequest -Uri $package.Url -OutFile $partial
            if ((Get-FileHash -LiteralPath $partial -Algorithm SHA1).Hash.ToLowerInvariant() -ne $package.Sha1) {
                throw "Checksum mismatch: $partial. The archive was not installed."
            }
            Move-Item -LiteralPath $partial -Destination $archive
        }
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA1).Hash.ToLowerInvariant() -ne $package.Sha1) {
            throw "Checksum mismatch: $archive. The archive was not installed."
        }
        $stage = Assert-LocalPath (Join-Path $localRoot ('stage-emulator-' + [Guid]::NewGuid().ToString('N')))
        Expand-Archive -LiteralPath $archive -DestinationPath $stage
        $source = Assert-LocalPath (Join-Path $stage $package.ArchiveDirectory)
        if (-not (Test-Path -LiteralPath (Join-Path $source $package.RequiredFile) -PathType Leaf)) {
            throw "Unexpected archive contents for $($package.Name): $stage"
        }
        New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
        # Both absolute paths have been checked against the scoped Android root.
        Move-Item -LiteralPath $source -Destination $destination
    }
    Assert-Packages
}

function Initialize-Avd {
    New-Item -ItemType Directory -Force -Path $avdPath | Out-Null
    if (-not (Test-Path -LiteralPath $avdConfig -PathType Leaf)) {
        @"
avd.ini.encoding=UTF-8
AvdId=$avdName
avd.ini.displayname=RuneCast API 36
abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.ramSize=4096
hw.lcd.width=720
hw.lcd.height=1600
hw.lcd.density=320
hw.keyboard=yes
hw.keyboard.lid=no
hw.mainKeys=no
hw.audioInput=no
hw.audioOutput=yes
hw.gpu.enabled=yes
hw.gpu.mode=host
hw.device.name=$avdName
hw.device.manufacturer=RuneCast
disk.dataPartition.size=6G
vm.heapSize=512
image.sysdir.1=$imageRoot\
tag.id=google_apis
tag.display=Google APIs
PlayStore.enabled=false
showDeviceFrame=no
skin.name=720x1600
skin.dynamic=yes
fastboot.forceColdBoot=yes
fastboot.forceFastBoot=no
fastboot.forceChosenSnapshotBoot=no
snapshot.present=no
"@ | Set-Content -LiteralPath $avdConfig -Encoding UTF8
    }
    if (-not (Test-Path -LiteralPath $avdLocator -PathType Leaf)) {
        @"
avd.ini.encoding=UTF-8
path=$avdPath
target=android-36
"@ | Set-Content -LiteralPath $avdLocator -Encoding UTF8
    }
    Assert-Avd
}

function Assert-Avd {
    if (-not (Test-Path -LiteralPath $avdConfig -PathType Leaf) -or
        -not (Test-Path -LiteralPath $avdLocator -PathType Leaf)) {
        throw 'The scoped AVD is missing. Run tools/android-emulator.ps1 -Action setup.'
    }
    $locator = Get-Content -LiteralPath $avdLocator -Raw
    $config = Get-Content -LiteralPath $avdConfig -Raw
    $pathMatch = [regex]::Match($locator, '(?m)^path=(.+)\r?$')
    $imageMatch = [regex]::Match($config, '(?m)^image\.sysdir\.1=(.+)\r?$')
    if (-not $pathMatch.Success -or -not $imageMatch.Success -or
        [IO.Path]::GetFullPath($pathMatch.Groups[1].Value.Trim()).TrimEnd('\','/') -ne $avdPath.TrimEnd('\','/') -or
        [IO.Path]::GetFullPath($imageMatch.Groups[1].Value.Trim()).TrimEnd('\','/') -ne $imageRoot.TrimEnd('\','/')) {
        throw 'Existing AVD paths do not match this workspace. They were preserved; resolve the paths while the AVD is stopped.'
    }
}

function Get-EmulatorState {
    $devices = Invoke-Native $adb @('devices','-l')
    $state = [ordered]@{
        checked_at_utc = [DateTime]::UtcNow.ToString('o')
        serial = $deviceSerial; avd_name = $null; avd_path = $null; running = $false
        adb_state = $null; owned = $false; boot_completed = $false
        physical_device_acceptance = 'open'
    }
    $match = [regex]::Match($devices.Output, '(?m)^emulator-5554\s+(\S+)')
    if ($match.Success) {
        $state.running = $true
        $state.adb_state = $match.Groups[1].Value
        if ($state.adb_state -eq 'device') {
            $nameResult = Invoke-Native $adb @('-s',$deviceSerial,'emu','avd','name') -AllowFailure
            if ($nameResult.ExitCode -eq 0) {
                $names = @($nameResult.Output -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne 'OK' })
                if ($names.Count -eq 1) {
                    $state.avd_name = $names[0]
                    if ($state.avd_name -eq $avdName) {
                        $pathResult = Invoke-Native $adb @('-s',$deviceSerial,'emu','avd','path') -AllowFailure
                        $paths = @($pathResult.Output -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne 'OK' })
                        if ($pathResult.ExitCode -eq 0 -and $paths.Count -eq 1 -and [IO.Path]::IsPathRooted($paths[0])) {
                            try {
                                $state.avd_path = [IO.Path]::GetFullPath($paths[0]).TrimEnd('\','/')
                                $state.owned = $state.avd_path.Equals($avdPath.TrimEnd('\','/'), [StringComparison]::OrdinalIgnoreCase)
                            } catch {
                                # A malformed path cannot establish workspace ownership.
                                $state.owned = $false
                            }
                        }
                    }
                }
            }
            if ($state.owned) {
                $boot = Invoke-Native $adb @('-s',$deviceSerial,'shell','getprop','sys.boot_completed') -AllowFailure
                $state.boot_completed = $boot.ExitCode -eq 0 -and $boot.Output.Trim() -eq '1'
            }
        }
    }
    return [pscustomobject]$state
}

function Assert-PortsFree {
    $listeners = [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
    if (@($listeners | Where-Object { $_.Port -in @(5554,5555) }).Count -gt 0) {
        throw 'Port 5554 or 5555 is already in use. No existing emulator or process was stopped.'
    }
}

try {
    New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
    $env:ANDROID_HOME = $sdkRoot
    $env:ANDROID_SDK_ROOT = $sdkRoot
    $env:ANDROID_AVD_HOME = $avdRoot
    if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) {
        throw 'Scoped platform-tools/adb.exe is missing. Run tools/bootstrap-android.ps1 first.'
    }
    switch ($Action) {
        'setup' {
            Install-Packages
            Initialize-Avd
            $actualConfig = [ordered]@{}
            foreach ($line in (Get-Content -LiteralPath $avdConfig)) {
                $entry = [regex]::Match($line, '^([^#=]+)=(.*)$')
                if ($entry.Success) { $actualConfig[$entry.Groups[1].Value.Trim()] = $entry.Groups[2].Value.Trim() }
            }
            Save-Json 'setup.json' ([ordered]@{
                emulator_version = '37.2.12'; emulator_build = '16428233'
                system_image = 'system-images;android-36;google_apis;x86_64'; image_revision = 7
                packages = $packages; sdk = $sdkRoot; avd = $avdPath
                display = "$($actualConfig['hw.lcd.width'])x$($actualConfig['hw.lcd.height']), density $($actualConfig['hw.lcd.density'])"
                ram_mb = $actualConfig['hw.ramSize']; cpu_cores = $actualConfig['hw.cpu.ncore']
                avd_configuration = $actualConfig
                physical_device_acceptance = 'open'
            })
            Write-Host "Scoped emulator ready: $avdName. Next: tools/android-emulator.ps1 -Action start"
        }
        'status' {
            $state = Get-EmulatorState
            Save-Json 'status.json' $state
            $state | ConvertTo-Json
        }
        'stop' {
            $state = Get-EmulatorState
            if (-not $state.running) {
                Assert-PortsFree
                Write-Host "$deviceSerial is not running."
            } elseif (-not $state.owned) {
                throw "Cannot prove $deviceSerial is $avdName; no emulator was stopped."
            } else {
                $result = Invoke-Native $adb @('-s',$deviceSerial,'emu','kill')
                $result.Output | Set-Content -LiteralPath (Join-Path $logRoot 'stop.txt') -Encoding UTF8
                Write-Host "Stopped $avdName. App and emulator data are retained."
            }
        }
        'start' {
            Assert-Packages
            Assert-Avd
            $state = Get-EmulatorState
            if ($state.running) {
                if (-not $state.owned) { throw "Port 5554 is occupied and ownership cannot be confirmed. No emulator was changed." }
                Save-Json 'status.json' $state
                Write-Host "$avdName already runs as $deviceSerial (boot completed: $($state.boot_completed))."
                if ($state.boot_completed -or $NoWait) { break }
            } else {
                Assert-PortsFree
                $acceleration = Invoke-Native $emulator @('-accel-check') -AllowFailure
                $acceleration.Output | Set-Content -LiteralPath (Join-Path $logRoot 'acceleration.txt') -Encoding UTF8
                if ($acceleration.ExitCode -ne 0) {
                    throw "Windows acceleration is unavailable. See output/qa/rc-021/emulator/acceleration.txt. This helper does not change host features."
                }
                $arguments = @('-avd',$avdName,'-port','5554','-no-snapshot','-no-boot-anim','-gpu',$Gpu,'-feature','GLESDynamicVersion','-accel','on')
                if (-not $Visible) { $arguments += '-no-window' }
                $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
                $stdout = Join-Path $logRoot "$runId-stdout.log"
                $stderr = Join-Path $logRoot "$runId-stderr.log"
                $windowStyle = if ($Visible) { 'Normal' } else { 'Hidden' }
                $process = Start-Process -FilePath $emulator -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle $windowStyle -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
                Save-Json 'launch.json' ([ordered]@{
                    started_at_utc = [DateTime]::UtcNow.ToString('o'); pid = $process.Id
                    avd = $avdName; serial = $deviceSerial; arguments = $arguments
                    stdout = $stdout; stderr = $stderr; physical_device_acceptance = 'open'
                })
                Write-Host "Started $avdName as $deviceSerial. Logs: $logRoot"
            }
            if ($NoWait) { break }
            $deadline = [DateTime]::UtcNow.AddSeconds($BootTimeoutSeconds)
            do {
                Start-Sleep -Seconds 5
                $state = Get-EmulatorState
                if ($state.boot_completed) {
                    Save-Json 'status.json' $state
                    Write-Host "$avdName boot completed. Use tools/android.ps1 -Action install -Device $deviceSerial."
                    break
                }
                # emulator.exe can hand off to qemu and exit before adb appears.
                # Use Android readiness and the timeout, not launcher lifetime.
                Write-Host 'Waiting for Android boot...'
            } while ([DateTime]::UtcNow -lt $deadline)
            if (-not $state.boot_completed) {
                throw "Android did not finish booting within $BootTimeoutSeconds seconds. The instance was left running; inspect logs or run -Action status."
            }
        }
    }
} catch {
    $failure = $_
    if (Test-Path -LiteralPath $logRoot -PathType Container) {
        Save-Json ('failure-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '.json') ([ordered]@{
            action = $Action; message = $failure.Exception.Message
            location = $failure.InvocationInfo.PositionMessage; stack = $failure.ScriptStackTrace
        })
    }
    Write-Error $failure -ErrorAction Continue
    exit 1
} finally {
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
}
exit 0
