$ErrorActionPreference = 'Stop'
$cleanupRoot = (Resolve-Path -LiteralPath 'C:\Dev\RuneCast').Path
$cleanupLedgerPath = Join-Path $cleanupRoot 'output\art\rc-011\cleanup\deletion-manifest.json'
$cleanupLedger = Get-Content -LiteralPath $cleanupLedgerPath -Raw | ConvertFrom-Json
if ($cleanupLedger.status -ne 'planned') { throw 'Only the prepared, not-yet-applied cleanup may run.' }
$cleanupSourceRoot = Join-Path $cleanupRoot 'source-assets\pilot'
$cleanupOutputRoot = Join-Path $cleanupRoot 'output\art\rc-011'
$cleanupStudyRoot = Join-Path $cleanupRoot 'output\imagegen'
$cleanupApprovedRoot = Join-Path $cleanupStudyRoot 'approved'
$cleanupTargets = @()

# Validate the complete finite list, including hashes, before deleting anything.
foreach ($entry in $cleanupLedger.removed) {
    $target = [IO.Path]::GetFullPath((Join-Path $cleanupRoot $entry.path))
    $inSource = $target.StartsWith($cleanupSourceRoot + '\', [StringComparison]::OrdinalIgnoreCase)
    $inOutput = $target.StartsWith($cleanupOutputRoot + '\', [StringComparison]::OrdinalIgnoreCase)
    $directStudy = [IO.Path]::GetDirectoryName($target).Equals($cleanupStudyRoot, [StringComparison]::OrdinalIgnoreCase)
    if (-not ($inSource -or $inOutput -or $directStudy)) { throw "Outside authorized art scope: $target" }
    if ($target.StartsWith($cleanupApprovedRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Approved image cannot be deleted: $target" }
    if ($target.StartsWith((Join-Path $cleanupOutputRoot 'cleanup') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Cleanup evidence cannot delete itself.' }
    $item = Get-Item -LiteralPath $target -Force
    if ($item.PSIsContainer) { throw "Expected an individual file: $target" }
    $ancestor = $item
    while ($ancestor -and $ancestor.FullName -ne $cleanupRoot) {
        if ($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse point is not allowed: $($ancestor.FullName)" }
        $ancestor = if ($ancestor.PSIsContainer) { $ancestor.Parent } else { $ancestor.Directory }
    }
    if ($item.Length -ne $entry.bytes) { throw "File size changed after audit: $target" }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "File content changed after audit: $target" }
    $cleanupTargets += $target
}
foreach ($entry in $cleanupLedger.retained_current_integrity) {
    $target = [IO.Path]::GetFullPath((Join-Path $cleanupRoot $entry.path))
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Current retained artwork changed before cleanup: $target" }
}
foreach ($entry in $cleanupLedger.updated) {
    $target = [IO.Path]::GetFullPath((Join-Path $cleanupRoot $entry.path))
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.after_sha256) { throw "Reconciled source changed before cleanup: $target" }
}

foreach ($target in $cleanupTargets) { Remove-Item -LiteralPath $target -Force }
foreach ($target in $cleanupTargets) { if (Test-Path -LiteralPath $target) { throw "Deletion did not finish: $target" } }

# Remove only empty directories inside the two verified art roots. No recursive
# removal is used, and every resolved path is checked again before removal.
$cleanupDirectories = foreach ($folder in @($cleanupSourceRoot, $cleanupOutputRoot)) {
    Get-ChildItem -LiteralPath $folder -Directory -Recurse -Force
}
foreach ($directory in ($cleanupDirectories | Sort-Object { $_.FullName.Length } -Descending)) {
    $target = [IO.Path]::GetFullPath($directory.FullName)
    if (-not ($target.StartsWith($cleanupSourceRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or $target.StartsWith($cleanupOutputRoot + '\', [StringComparison]::OrdinalIgnoreCase))) { throw 'Empty-directory path escaped art roots.' }
    if ($directory.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse directory is not allowed.' }
    if (@(Get-ChildItem -LiteralPath $target -Force).Count -eq 0) { Remove-Item -LiteralPath $target -Force }
}
$cleanupLedger.status = 'completed'
$cleanupLedger | Add-Member -NotePropertyName deleted_file_count -NotePropertyValue $cleanupTargets.Count
$cleanupLedger | Add-Member -NotePropertyName deleted_bytes -NotePropertyValue (($cleanupLedger.removed | Measure-Object bytes -Sum).Sum)
$cleanupLedger | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $cleanupLedgerPath -Encoding utf8
[pscustomobject]@{ status = 'completed'; deleted_files = $cleanupTargets.Count; deleted_MiB = [Math]::Round($cleanupLedger.deleted_bytes / 1MB, 2) } | ConvertTo-Json
