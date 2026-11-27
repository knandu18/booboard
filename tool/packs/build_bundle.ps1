# SPDX-License-Identifier: GPL-3.0-or-later
#
# Builds the play flavour's app bundle with the Play asset packs, then validates it and makes APK sets with
# bundletool. OWNER: Wave 5-C. Needs Java 17+ on PATH and Flutter.
#
#   powershell -ExecutionPolicy Bypass -File tool/packs/build_bundle.ps1 [-PacksDir <dir>] [-PubKey <pem>] [-SkipFlutter]
#
# Outputs (in build/packs/bundle/, not committed):
#   app-play-release.aab         the bundle with the asset packs
#   universal.apks               one APK set that runs on any device (checks the whole bundle)
#   local-testing.apks           APK set for `bundletool build-apks --local-testing`: on-demand packs installed
#                                from the local set, no Play needed (orchestrator's emulator test)
#
# bundletool 1.18.3 (Apache-2.0) is downloaded to %USERPROFILE%\.booboard\tools\ and its SHA-256 is printed; record
# it in docs/release/asset-packs.md. Nothing is uploaded anywhere.
param(
    [string]$PacksDir = (Join-Path $env:USERPROFILE '.booboard\packs\signed'),
    [string]$PubKey = '',
    [switch]$SkipFlutter
)

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$BundletoolVersion = '1.18.3'
$toolsDir = Join-Path $env:USERPROFILE '.booboard\tools'
$jar = Join-Path $toolsDir "bundletool-all-$BundletoolVersion.jar"
$out = Join-Path $repo 'build\packs\bundle'
New-Item -ItemType Directory -Force -Path $toolsDir, $out | Out-Null

# 1. Copy and (optionally) verify the packs into the asset pack modules.
$copyArgs = @('-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'copy_asset_packs.ps1'), '-PacksDir', $PacksDir)
if ($PubKey -ne '') { $copyArgs += @('-PubKey', $PubKey) }
& powershell @copyArgs
if ($LASTEXITCODE -ne 0) { throw 'copy_asset_packs.ps1 failed' }

# 2. Bundle. Flutter builds the play flavour with the asset pack modules listed in android/app/build.gradle.kts.
if (-not $SkipFlutter) {
    Push-Location $repo
    try {
        flutter build appbundle --flavor play --release
        if ($LASTEXITCODE -ne 0) { throw 'flutter build appbundle failed' }
    } finally {
        Pop-Location
    }
}
$aab = Get-ChildItem -Path (Join-Path $repo 'build\app\outputs\bundle\playRelease') -Filter '*.aab' -ErrorAction Stop |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item -LiteralPath $aab.FullName -Destination (Join-Path $out 'app-play-release.aab') -Force

# 3. bundletool: fetch once, pin by checksum on first download.
if (-not (Test-Path -LiteralPath $jar)) {
    $url = "https://github.com/google/bundletool/releases/download/$BundletoolVersion/bundletool-all-$BundletoolVersion.jar"
    Invoke-WebRequest -Uri $url -OutFile $jar -UseBasicParsing
}
$hash = (Get-FileHash -LiteralPath $jar -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "bundletool $BundletoolVersion sha256 $hash"

$bundle = Join-Path $out 'app-play-release.aab'
& java -jar $jar validate "--bundle=$bundle"
if ($LASTEXITCODE -ne 0) { throw 'bundletool validate failed' }

$universalApks = Join-Path $out 'universal.apks'
& java -jar $jar build-apks "--bundle=$bundle" "--output=$universalApks" --mode=universal --overwrite
if ($LASTEXITCODE -ne 0) { throw 'bundletool build-apks (universal) failed' }

$localApks = Join-Path $out 'local-testing.apks'
& java -jar $jar build-apks "--bundle=$bundle" "--output=$localApks" --local-testing --overwrite
if ($LASTEXITCODE -ne 0) { throw 'bundletool build-apks --local-testing failed' }

Write-Output "done: $out"
Write-Output 'Install the local-testing set on the emulator with: bundletool install-apks --apks=<local-testing.apks> (Wave 5 orchestrator only).'
