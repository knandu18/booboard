# SPDX-License-Identifier: GPL-3.0-or-later
#
# Rebuilds the reduced onnxruntime 1.28.0 AAR for BooBoard (Wave 4-D, plan Part 1). Run from the repo root.
#
# STATUS: NOT RUN. Written from the brief, not tested. The build could not start because the
# onnxruntime source (github.com/microsoft/onnxruntime, tag v1.28.0) was not downloadable from this
# PC: GitHub answered 404 for the repository, its tags and its API. See docs/notices/onnxruntime.md.
# Check the exact flags against `build.bat --help` and the ORT docs for 1.28 before the first run.
#
# Steps:
#   1. the operator config (tool/onnxruntime/ops.config) from create_reduced_build_config.py over the
#      staged models (read only), if it is missing;
#   2. one build per ABI (arm64-v8a, armeabi-v7a, x86_64) with MinSizeRel, the reduced op set, the
#      Java API and no tests;
#   3. the AAR packaging step;
#   4. copy to android\app\libs\onnxruntime-booboard-1.28.0.aar and run check_aar.ps1.
#
# Do NOT change android\app\build.gradle.kts unless check_aar.ps1 passes.
param(
  [string]$Src = "$env:USERPROFILE\.booboard\ort-build\src",
  [string]$Ndk = "$env:LOCALAPPDATA\Android\Sdk\ndk\28.2.13676358",
  [string]$Staging = "$env:USERPROFILE\.booboard\packs\staging",
  [string[]]$Abis = @('arm64-v8a', 'armeabi-v7a', 'x86_64'),
  [string]$Config = "$PSScriptRoot\ops.config"
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$aarOut = Join-Path $repo 'android\app\libs\onnxruntime-booboard-1.28.0.aar'

if (-not (Test-Path (Join-Path $Src 'build.bat'))) {
  throw "onnxruntime v1.28.0 source not found at $Src (set -Src). Clone https://github.com/microsoft/onnxruntime at tag v1.28.0."
}
if (-not (Test-Path $Ndk)) { throw "NDK 28.2 not found at $Ndk (set -Ndk)." }

# 1. Operator config. The staged models are read only; the script only reads them.
if (-not (Test-Path $Config)) {
  Write-Output 'Generating the operator config from the staged models...'
  $models = Get-ChildItem $Staging -Recurse -Filter *.onnx | ForEach-Object { $_.FullName }
  # Argument order as in the ORT tool; confirm with --help on the 1.28 checkout.
  & python (Join-Path $Src 'tools\python\create_reduced_build_config.py') --format ORT $Staging $Config
  if ($LASTEXITCODE -ne 0) { throw "create_reduced_build_config.py failed ($($models.Count) models)" }
}

# 2. One build per ABI. Keep ONNX model support: no --minimal_build (packs ship .onnx files).
foreach ($abi in $Abis) {
  Write-Output "Building $abi..."
  Push-Location $Src
  try {
    & .\build.bat --config MinSizeRel --android --android_abi $abi --android_api 26 `
      --android_ndk_path $Ndk --build_java --include_ops_by_config $Config `
      --skip_tests --parallel --cmake_generator Ninja
    if ($LASTEXITCODE -ne 0) { throw "build failed for $abi (exit $LASTEXITCODE)" }
  } finally {
    Pop-Location
  }
}

# 3. Package the AAR from the per-ABI outputs (ORT's packaging script; check its usage on 1.28).
Push-Location $Src
try {
  & python 'tools\ci_build\github\android\build_aar_package.py' --build_dir 'build\Android' --config MinSizeRel
  if ($LASTEXITCODE -ne 0) { throw "AAR packaging failed (exit $LASTEXITCODE)" }
} finally {
  Pop-Location
}
$aar = Get-ChildItem (Join-Path $Src 'build\Android') -Recurse -Filter 'onnxruntime*.aar' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $aar) { throw 'no onnxruntime*.aar found under build\Android' }

# 4. Install it and check it. The Gradle line is switched only after the check passes.
Copy-Item $aar.FullName $aarOut -Force
Write-Output "AAR copied to $aarOut"
& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check_aar.ps1') -Aar $aarOut -Ndk $Ndk -Config $Config
exit $LASTEXITCODE
