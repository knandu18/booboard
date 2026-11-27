# SPDX-License-Identifier: GPL-3.0-or-later
#
# Builds the release APKs for both flavours, runs the gates and writes the release report.
# Nothing is published: the output stays in build\release-report\ for a person to review.
#
#   powershell -ExecutionPolicy Bypass -File tool\release\build_release.ps1
#   powershell -ExecutionPolicy Bypass -File tool\release\build_release.ps1 -SourceUrl https://github.com/knandu18/booboard -SkipChecks
#
# Steps: clean tree check, pinned Flutter check, signing check, format, analyze, flutter test, JVM tests,
# then per flavour: flutter build apk --release --flavor <f> --split-per-abi, the permission gate
# (tool/check_release_permissions.sh through Git Bash), sizes, SHA-256 sums.
# Without release keys the APKs are signed with the debug key; the report says so and they must not be published.
param(
    [string[]]$Flavors = @('foss', 'play'),
    [string]$SourceUrl = 'https://github.com/knandu18/booboard',
    [switch]$AllowDirty,
    [switch]$SkipChecks
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

$reportDir = Join-Path $repoRoot 'build\release-report'
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$log = New-Object System.Collections.Generic.List[string]
function Say([string]$Text) { Write-Host $Text; $script:log.Add($Text) }
function Run-Step([string]$Name, [scriptblock]$Command) {
    Say "==> $Name"
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Name failed (exit $LASTEXITCODE)" }
    Say ("    {0} s" -f [math]::Round($watch.Elapsed.TotalSeconds, 1))
}

# 1. Clean tree: a release must be reproducible from a commit.
$dirty = & git status --porcelain
if ($dirty -and -not $AllowDirty) {
    throw "The working tree has uncommitted changes. Commit them first, or pass -AllowDirty for a local test build."
}
$commit = (& git rev-parse --short HEAD).Trim()
Say "Commit: $commit$(if ($dirty) { ' (DIRTY tree)' })"

# 2. Pinned Flutter.
$pinned = (Get-Content (Join-Path $repoRoot 'tool\release\flutter-version.txt') -Raw).Trim()
$installed = ((& flutter --version) | Select-Object -First 1)
if ($installed -notmatch [regex]::Escape("Flutter $pinned ")) {
    throw "Flutter $pinned is required (tool/release/flutter-version.txt). Found: $installed"
}
Say "Flutter: $pinned (pinned)"

# 3. Signing.
$hasSigning = (Test-Path (Join-Path $repoRoot 'android\key.properties')) -or
    ($env:BOOBOARD_KEYSTORE_PATH -and $env:BOOBOARD_KEYSTORE_PASSWORD -and $env:BOOBOARD_KEY_ALIAS -and $env:BOOBOARD_KEY_PASSWORD)
$signing = if ($hasSigning) { 'release key' } else { 'DEBUG KEY (no release keys: do not publish)' }
Say "Signing: $signing"

# 4. Checks.
if (-not $SkipChecks) {
    # The generated gen-l10n files (lib/l10n/app_localizations*.dart) are not formatted by the generator on
    # Flutter 3.50 and are excluded here. Formatting them is an open item (checklist, section G).
    Run-Step 'dart format' {
        # Directories, not a file list: a long list overflows the Windows command line of dart.bat.
        $targets = @(Get-ChildItem -Path lib -Directory | Where-Object { $_.Name -ne 'l10n' } | ForEach-Object { $_.FullName })
        $targets += Get-ChildItem -Path lib -File -Filter *.dart | ForEach-Object { $_.FullName }
        $targets += 'test', 'pigeons' | ForEach-Object { (Resolve-Path $_).Path }
        & dart format --line-length 120 --output=none --set-exit-if-changed @targets
    }
    Run-Step 'flutter pub get' { & flutter pub get }
    Run-Step 'flutter analyze' { & flutter analyze }
    Run-Step 'flutter test' { & flutter test }
    # With flavours the task names carry the flavour (testFossDebugUnitTest, testPlayDebugUnitTest).
    Run-Step 'JVM unit tests (foss and play)' {
        Push-Location (Join-Path $repoRoot 'android')
        try { & .\gradlew.bat ':app:testFossDebugUnitTest' ':app:testPlayDebugUnitTest' } finally { Pop-Location }
    }
}

# 5. Release APKs per flavour.
$apks = New-Object System.Collections.Generic.List[object]
$buildSeconds = @{}
foreach ($flavor in $Flavors) {
    $flutterArgs = @('build', 'apk', '--release', '--flavor', $flavor, '--split-per-abi')
    if ($SourceUrl) { $flutterArgs += "--dart-define=BOOBOARD_SOURCE_URL=$SourceUrl" }
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    Run-Step "flutter build apk --release --flavor $flavor --split-per-abi" { & flutter @flutterArgs }
    $buildSeconds[$flavor] = [math]::Round($watch.Elapsed.TotalSeconds, 0)
    # Flutter names split flavour APKs app-<abi>-<flavour>-release.apk (the ABI comes first).
    Get-ChildItem (Join-Path $repoRoot "build\app\outputs\flutter-apk\app-*-$flavor-release.apk") | ForEach-Object {
        $apks.Add($_)
    }
}
if ($apks.Count -eq 0) { throw 'No release APKs were produced.' }

# 6. Permission gate (Git Bash). It fails on INTERNET, network state, or onnxruntime telemetry classes.
$bash = 'C:\Program Files\Git\bin\bash.exe'
if (-not (Test-Path $bash)) { throw "Git Bash not found at $bash (needed for tool/check_release_permissions.sh)" }
$relative = $apks | ForEach-Object { 'build/app/outputs/flutter-apk/' + $_.Name }
$gateLog = Join-Path $reportDir 'permission-gate.txt'
$quoted = ($relative | ForEach-Object { "'$_'" }) -join ' '
# The gate looks for aapt2 under ANDROID_HOME with a POSIX path, so give Git Bash the /c/... form.
$sdkWindows = $env:ANDROID_HOME
if ($sdkWindows -match '^([A-Za-z]):\\(.*)$') {
    $env:ANDROID_HOME = '/' + $Matches[1].ToLower() + '/' + ($Matches[2] -replace '\\', '/')
}
try {
    $gateOutput = & $bash -lc "cd '$($repoRoot.Replace('\', '/'))' && bash tool/check_release_permissions.sh $quoted"
    $gateExit = $LASTEXITCODE
} finally {
    $env:ANDROID_HOME = $sdkWindows
}
$gateOutput | Tee-Object -FilePath $gateLog | ForEach-Object { Write-Host $_ }
if ($gateExit -ne 0) { throw "Permission gate failed. See $gateLog" }
Say 'Permission gate: passed for every APK'

# 7. Sizes and sums.
$sizeLines = $apks | Sort-Object Name | ForEach-Object {
    '{0},{1},{2}' -f $_.Name, $_.Length, [math]::Round($_.Length / 1MB, 1)
}
$sizesCsv = Join-Path $reportDir 'sizes.csv'
Set-Content -Path $sizesCsv -Value (@('file,bytes,mib') + $sizeLines) -Encoding ascii
$sums = $apks | Sort-Object Name | ForEach-Object {
    '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLower(), $_.Name
}
$sumsFile = Join-Path $reportDir 'SHA256SUMS.txt'
Set-Content -Path $sumsFile -Value $sums -Encoding ascii

Say ''
Say "Commit $commit, signing: $signing"
foreach ($flavor in $Flavors) { Say "Build time $flavor : $($buildSeconds[$flavor]) s" }
Say 'APK sizes (MiB):'
$sizeLines | ForEach-Object { Say "  $_" }
Say "Files: $sizesCsv, $sumsFile, $gateLog"
Set-Content -Path (Join-Path $reportDir 'summary.txt') -Value $log -Encoding utf8
