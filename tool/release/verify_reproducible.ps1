# SPDX-License-Identifier: GPL-3.0-or-later
#
# Reproducibility check for the release APK. Builds the same commit twice from two fresh clones in
# two different directories (paths are part of what a build can leak), then compares the APKs entry by
# entry. It is a normalising diff, not a byte comparison: the zip container and the signing block
# are ignored, and so are META-INF signing files (they change with the key). Everything else must match.
#
#   powershell -ExecutionPolicy Bypass -File tool\release\verify_reproducible.ps1
#   powershell -ExecutionPolicy Bypass -File tool\release\verify_reproducible.ps1 -Flavor foss -KeepClones
#
# Requires a committed, clean tree (the clones are made from the commit, not from the working copy).
# Each build is a full flutter build; expect a long run. The report goes to build\repro-report.txt.
param(
    [string]$Flavor = 'foss',
    [string]$Abi = 'android-arm64',
    [string]$WorkRoot = (Join-Path $env:TEMP 'booboard-repro'),
    [switch]$KeepClones,
    [switch]$SameDirectory
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

if (& git status --porcelain) { throw 'Commit or stash your changes first: the check builds the commit, not the working tree.' }
$commit = (& git rev-parse HEAD).Trim()
$run = Join-Path $WorkRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
$cloneA = Join-Path $run 'a'
# Short folder names: the Flutter shader build writes long paths, and MAX_PATH (260) breaks it on Windows.
$cloneB = Join-Path $run 'b'
New-Item -ItemType Directory -Force -Path $run | Out-Null

function Get-Clone([string]$Dir) {
    & git clone --quiet $repoRoot $Dir
    if ($LASTEXITCODE -ne 0) { throw "git clone into $Dir failed" }
    & git -C $Dir checkout --quiet --detach $commit
    if ($LASTEXITCODE -ne 0) { throw "checkout of $commit in $Dir failed" }
}

function Build-Apk([string]$Dir) {
    Push-Location $Dir
    try {
        & flutter pub get | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed in $Dir" }
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        # Out-Host keeps flutter's output off the pipeline, so the function returns only the APK path.
        & flutter build apk --release --flavor $Flavor --split-per-abi --target-platform $Abi | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "flutter build failed in $Dir" }
        Write-Host ("    built in {0} s" -f [math]::Round($watch.Elapsed.TotalSeconds, 0))
        # Flutter names split flavour APKs app-<abi>-<flavour>-release.apk.
        $apk = Get-ChildItem (Join-Path $Dir "build\app\outputs\flutter-apk\app-*-$Flavor-release.apk") | Select-Object -First 1
        if (-not $apk) { throw "no APK in $Dir" }
        return $apk.FullName
    } finally { Pop-Location }
}

function Get-EntryHash([System.IO.Compression.ZipArchiveEntry]$Entry) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $stream = $Entry.Open()
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLower() }
    finally { $stream.Dispose(); $sha.Dispose() }
}

Write-Host "Commit $commit, flavour $Flavor, $Abi"
if ($SameDirectory) {
    # Same path twice: a fresh clone at the same folder, built twice. Separates the build-path leak from
    # any other non-determinism. F-Droid builds at one fixed path, so this is the case that matters for it.
    $cloneB = $cloneA
    Write-Host '==> Clone and build (path 1)'
    Get-Clone $cloneA
    $apkA = Build-Apk $cloneA
    $keep = Join-Path $run 'first.apk'
    Copy-Item -LiteralPath $apkA -Destination $keep
    Remove-Item -Recurse -Force $cloneA
    Write-Host '==> Fresh clone at the same path and build (path 2)'
    Get-Clone $cloneA
    $apkA = Build-Apk $cloneA
    $apkB = Join-Path $run 'second.apk'
    Copy-Item -LiteralPath $apkA -Destination $apkB
    $apkA = $keep
} else {
    Write-Host '==> Clone A and build'
    Get-Clone $cloneA
    $apkA = Build-Apk $cloneA
    Write-Host '==> Clone B (another folder) and build'
    Get-Clone $cloneB
    $apkB = Build-Apk $cloneB
}

# --- Normalising comparison ----------------------------------------------------------------------
$zipA = [System.IO.Compression.ZipFile]::OpenRead($apkA)
$zipB = [System.IO.Compression.ZipFile]::OpenRead($apkB)
try {
    $entriesA = @{}; foreach ($e in $zipA.Entries) { $entriesA[$e.FullName] = $e }
    $entriesB = @{}; foreach ($e in $zipB.Entries) { $entriesB[$e.FullName] = $e }
    $names = @($entriesA.Keys + $entriesB.Keys | Sort-Object -Unique)

    $identical = 0
    $different = New-Object System.Collections.Generic.List[string]
    $onlyIn = New-Object System.Collections.Generic.List[string]
    $ignored = New-Object System.Collections.Generic.List[string]
    $timestampOnly = 0
    foreach ($name in $names) {
        if ($name -like 'META-INF/*') { $ignored.Add($name); continue }
        if (-not $entriesA.ContainsKey($name)) { $onlyIn.Add("only in second: $name"); continue }
        if (-not $entriesB.ContainsKey($name)) { $onlyIn.Add("only in first: $name"); continue }
        $a = $entriesA[$name]; $b = $entriesB[$name]
        if ($a.Length -eq $b.Length -and (Get-EntryHash $a) -eq (Get-EntryHash $b)) {
            $identical++
            if ($a.LastWriteTime -ne $b.LastWriteTime) { $timestampOnly++ }
        } else {
            $different.Add("$name (sizes $($a.Length) / $($b.Length))")
        }
    }
    $orderA = ($zipA.Entries | Where-Object { $_.FullName -notlike 'META-INF/*' } | ForEach-Object FullName) -join '|'
    $orderB = ($zipB.Entries | Where-Object { $_.FullName -notlike 'META-INF/*' } | ForEach-Object FullName) -join '|'
    $orderSame = $orderA -eq $orderB
} finally {
    $zipA.Dispose(); $zipB.Dispose()
}

$shaA = (Get-FileHash -Algorithm SHA256 -LiteralPath $apkA).Hash.ToLower()
$shaB = (Get-FileHash -Algorithm SHA256 -LiteralPath $apkB).Hash.ToLower()

$report = New-Object System.Collections.Generic.List[string]
$mode = if ($SameDirectory) { 'two builds at the same path' } else { 'two builds at two different paths' }
$report.Add("Reproducibility check, commit $commit, flavour $Flavor, $Abi, $mode")
$report.Add("Date: $(Get-Date -Format 'yyyy-MM-dd')")
$report.Add("APK A sha256: $shaA  ($([math]::Round((Get-Item $apkA).Length / 1MB, 2)) MiB)")
$report.Add("APK B sha256: $shaB  ($([math]::Round((Get-Item $apkB).Length / 1MB, 2)) MiB)")
$report.Add("Whole-file byte identical: $($shaA -eq $shaB)")
$report.Add("Entries identical (content): $identical; entries identical but with different timestamps: $timestampOnly")
$report.Add("Entries with different content: $($different.Count)")
foreach ($d in $different) { $report.Add("  DIFF $d") }
$report.Add("Entries present in one APK only: $($onlyIn.Count)")
foreach ($o in $onlyIn) { $report.Add("  $o") }
$report.Add("Entry order identical: $orderSame")
$report.Add("Ignored META-INF signing entries: $($ignored -join ', ')")

$reportFile = Join-Path $repoRoot 'build\repro-report.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $reportFile) | Out-Null
Set-Content -Path $reportFile -Value $report -Encoding utf8
$report | ForEach-Object { Write-Host $_ }
Write-Host "Report: $reportFile"

if (-not $KeepClones) { Remove-Item -Recurse -Force $run -ErrorAction SilentlyContinue }

if ($different.Count -gt 0 -or $onlyIn.Count -gt 0) { exit 1 }
exit 0
