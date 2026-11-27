# SPDX-License-Identifier: GPL-3.0-or-later
#
# Checks a reduced onnxruntime AAR (Wave 4-D). Exits 1 unless all three checks pass:
#   1. every ABI's libonnxruntime.so exports OrtGetApiBase@@VERS_1.28.0 (llvm-readelf from the NDK);
#   2. the AAR has no ai/onnxruntime/telemetry classes and no <uses-permission> in its manifest;
#   3. every operator used by every staged model (tool/onnxruntime/model_ops.txt, written by
#      model_ops.py) is in the build's operator config (tool/onnxruntime/ops.config).
#
# Usage (from the repo root):
#   powershell -ExecutionPolicy Bypass -File tool\onnxruntime\check_aar.ps1
param(
  [string]$Aar = "$PSScriptRoot\..\..\android\app\libs\onnxruntime-booboard-1.28.0.aar",
  [string]$Ndk = "$env:LOCALAPPDATA\Android\Sdk\ndk\28.2.13676358",
  [string]$Config = "$PSScriptRoot\ops.config",
  [string]$OpsList = "$PSScriptRoot\model_ops.txt"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$failures = New-Object System.Collections.Generic.List[string]
$Aar = (Resolve-Path $Aar).Path

$tmp = Join-Path $env:TEMP ("booboard-aar-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $zipCopy = Join-Path $tmp 'aar.zip'
  Copy-Item $Aar $zipCopy
  $unpacked = Join-Path $tmp 'aar'
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zipCopy, $unpacked)

  # 1. Symbol version on every ABI.
  $readelf = Join-Path $Ndk 'toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-readelf.exe'
  if (-not (Test-Path $readelf)) { $failures.Add("llvm-readelf not found at $readelf (set -Ndk)") }
  $abis = @('arm64-v8a', 'armeabi-v7a', 'x86_64')
  foreach ($abi in $abis) {
    $so = Join-Path $unpacked "jni\$abi\libonnxruntime.so"
    if (-not (Test-Path $so)) { $failures.Add("missing $abi/libonnxruntime.so"); continue }
    $size = (Get-Item $so).Length
    $sha = (Get-FileHash $so -Algorithm SHA256).Hash
    if (Test-Path $readelf) {
      $syms = & $readelf --dyn-syms $so
      if (-not ($syms | Select-String -SimpleMatch 'OrtGetApiBase@@VERS_1.28.0')) {
        $failures.Add("$abi/libonnxruntime.so does not export OrtGetApiBase@@VERS_1.28.0")
      }
    }
    Write-Output ("{0}: libonnxruntime.so {1:N0} bytes sha256 {2}" -f $abi, $size, $sha)
  }

  # 2. No telemetry classes, no permissions.
  $classesJar = Join-Path $unpacked 'classes.jar'
  if (-not (Test-Path $classesJar)) {
    $failures.Add('classes.jar missing from the AAR')
  } else {
    $jar = [System.IO.Compression.ZipFile]::OpenRead($classesJar)
    try {
      $telemetry = @($jar.Entries | Where-Object { $_.FullName -like 'ai/onnxruntime/telemetry/*' })
      if ($telemetry.Count -gt 0) { $failures.Add("$($telemetry.Count) ai/onnxruntime/telemetry classes in classes.jar") }
    } finally { $jar.Dispose() }
  }
  $manifest = Join-Path $unpacked 'AndroidManifest.xml'
  if (Test-Path $manifest) {
    if (Select-String -Path $manifest -Pattern '<uses-permission' -Quiet) {
      $failures.Add('AndroidManifest.xml declares a <uses-permission>')
    }
  } else {
    $failures.Add('AndroidManifest.xml missing from the AAR')
  }
}
finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

# 3. Every model operator is in the build config.
if (-not (Test-Path $OpsList)) {
  $failures.Add("$OpsList missing: run tool\onnxruntime\model_ops.py first")
} elseif (-not (Test-Path $Config)) {
  $failures.Add("$Config missing: the reduced-build operator config has not been generated")
} else {
  $built = New-Object System.Collections.Generic.HashSet[string]
  foreach ($line in Get-Content $Config) {
    if ($line -match '^\s*#' -or $line -notmatch ';') { continue }
    $parts = $line.Split(';')
    if ($parts.Count -lt 3) { continue }
    foreach ($op in $parts[2].Split(',')) {
      if ($op.Trim()) { [void]$built.Add("$($parts[0].Trim());$($op.Trim())") }
    }
  }
  $missing = @()
  foreach ($line in Get-Content $OpsList) {
    if ($line -match '^\s*#' -or $line -notmatch ';') { continue }
    $key = ($line.Split(';')[0..1]) -join ';'
    if (-not $built.Contains($key)) { $missing += $key }
  }
  if ($missing.Count -gt 0) {
    $failures.Add("operators used by the models but missing from the build: $($missing -join ', ')")
  }
}

if ($failures.Count -gt 0) {
  Write-Output 'CHECK FAILED:'
  $failures | ForEach-Object { Write-Output "  - $_" }
  exit 1
}
Write-Output 'CHECK PASSED: symbols, telemetry and permissions, and model operators.'
exit 0
