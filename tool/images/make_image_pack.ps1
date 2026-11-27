# SPDX-License-Identifier: GPL-3.0-or-later
#
# Builds the dev-signed BooBoard Images test pack (images-lcm-dreamshaper-v7.boopack) on the PC.
# Everything is local: no downloads. Needs the pinned weights and the sd-cli build (see README.md).
#
#   powershell -ExecutionPolicy Bypass -File tool\images\make_image_pack.ps1
#   powershell -ExecutionPolicy Bypass -File tool\images\make_image_pack.ps1 -LicenseFile C:\path\LICENSE.txt -UseRulesFile C:\path\USE-RULES.txt
#
# Steps: 1) q8_0 GGUF without the full VAE  2) staging folder  3) sign with the DEV key and verify.
# The release pack key is never used: -KeyPath is refused if it points into a "release" folder.
param(
  [string]$ImagesDir = (Join-Path $env:USERPROFILE '.booboard\packs\download\images'),
  [string]$SdCli = (Join-Path $env:USERPROFILE '.booboard\tools\sdcpp\build-win\bin\sd-cli.exe'),
  [string]$KeyPath = (Join-Path $env:USERPROFILE '.booboard\keys\pack-dev.pem'),
  [string]$StagingDir = (Join-Path $env:USERPROFILE '.booboard\packs\staging\images-lcm-dreamshaper-v7'),
  [string]$OutPack = (Join-Path $env:USERPROFILE '.booboard\packs\signed\dev-signed\images-lcm-dreamshaper-v7.boopack'),
  [string]$LicenseFile = '',
  [string]$UseRulesFile = '',
  [switch]$KeepIntermediate
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Assert-Exit([string]$what) {
  if ($LASTEXITCODE -ne 0) { throw "$what failed (exit code $LASTEXITCODE)" }
}

if ($KeyPath -match '(?i)[\\/]release([\\/]|$)') { throw 'Refusing to use a key from a release folder. This script signs with the DEV key only.' }
foreach ($p in @($SdCli, $KeyPath)) { if (-not (Test-Path -LiteralPath $p)) { throw "not found: $p" } }

$model = Join-Path $ImagesDir 'lcm-dreamshaper-v7'
$taesd = Join-Path $ImagesDir 'taesd\diffusion_pytorch_model.safetensors'
if (-not (Test-Path -LiteralPath $taesd)) { throw "not found: $taesd" }
$novae = Join-Path $ImagesDir 'novae'
New-Item -ItemType Directory -Force $novae | Out-Null
$f16 = Join-Path $novae 'lcm-dreamshaper-v7-f16-novae.gguf'
$q8 = Join-Path $novae 'lcm-dreamshaper-v7-q8_0-novae.gguf'

# --- 1. q8_0 GGUF without the full VAE ------------------------------------------------------------------------
# A diffusers folder without vae\ is accepted by the converter (the VAE is optional there). Hard links, no copy.
$tmp = Join-Path $novae 'diffusers-novae'
if (Test-Path -LiteralPath $tmp) { Remove-Item -Recurse -Force -LiteralPath $tmp }
$parts = 'model_index.json',
  'unet\config.json', 'unet\diffusion_pytorch_model.safetensors',
  'text_encoder\config.json', 'text_encoder\model.safetensors',
  'tokenizer\merges.txt', 'tokenizer\special_tokens_map.json', 'tokenizer\tokenizer_config.json', 'tokenizer\vocab.json',
  'scheduler\scheduler_config.json'
foreach ($rel in $parts) {
  $from = Join-Path $model $rel
  if (-not (Test-Path -LiteralPath $from)) { throw "not found: $from" }
  $to = Join-Path $tmp $rel
  New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
  try { New-Item -ItemType HardLink -Path $to -Target $from | Out-Null } catch { Copy-Item -LiteralPath $from -Destination $to }
}
Write-Host '== convert to f16 (no vae folder)'
& $SdCli -M convert -m $tmp --type f16 -o $f16
Assert-Exit 'convert to f16'
Write-Host '== quantize f16 -> q8_0'
& $SdCli -M convert -m $f16 --type q8_0 -o $q8
Assert-Exit 'convert to q8_0'
Remove-Item -Recurse -Force -LiteralPath $tmp
if (-not $KeepIntermediate) { Remove-Item -Force -LiteralPath $f16 }

$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
  Write-Host '== check: no VAE tensors in the GGUF'
  & $python.Source -I -X utf8 (Join-Path $PSScriptRoot 'gguf_list_tensors.py') $q8 --fail-on first_stage_model. vae.
  Assert-Exit 'GGUF check (a VAE tensor is still in the file)'
} else {
  Write-Warning 'python not found: skipped the GGUF tensor check'
}

# --- 2. staging folder ---------------------------------------------------------------------------------------
Write-Host "== staging $StagingDir"
if (Test-Path -LiteralPath $StagingDir) { Remove-Item -Recurse -Force -LiteralPath $StagingDir }
New-Item -ItemType Directory -Force (Join-Path $StagingDir 'model') | Out-Null
function Stage-File([string]$from, [string]$to) {
  try { New-Item -ItemType HardLink -Path $to -Target $from | Out-Null } catch { Copy-Item -LiteralPath $from -Destination $to }
}
Stage-File $q8 (Join-Path $StagingDir 'model\model.gguf')
Stage-File $taesd (Join-Path $StagingDir 'model\taesd.safetensors')

if ($LicenseFile) {
  Copy-Item -LiteralPath $LicenseFile -Destination (Join-Path $StagingDir 'LICENSE.txt')
} else {
  $text = @'
*** PLACEHOLDER: the full licence text is still to be added before release. ***

Model:   SimianLuo/LCM_Dreamshaper_v7 (revision a85df6a), a fine-tune of Stable Diffusion 1.5.
         Licence: CreativeML-OpenRAIL-M (the model card says MIT, but it is built on Stable Diffusion 1.5,
         so the CreativeML Open RAIL-M use restrictions are passed on).
TAESD:   madebyollin/taesd (revision 614f768), MIT licence.

Full text to be added before release.
'@
  Set-Content -LiteralPath (Join-Path $StagingDir 'LICENSE.txt') -Value $text -Encoding ASCII
}
if ($UseRulesFile) {
  Copy-Item -LiteralPath $UseRulesFile -Destination (Join-Path $StagingDir 'USE-RULES.txt')
} else {
  $text = @'
*** PLACEHOLDER: to be filled in Phase 4. ***

This file will state the CreativeML Open RAIL-M use restrictions (Attachment A) in plain words.
The model is a Stable Diffusion 1.5 derivative, so those restrictions apply to its output and use.
'@
  Set-Content -LiteralPath (Join-Path $StagingDir 'USE-RULES.txt') -Value $text -Encoding ASCII
}

# --- 3. sign with the DEV key and verify ---------------------------------------------------------------------
Write-Host "== sign (dev key) -> $OutPack"
New-Item -ItemType Directory -Force (Split-Path $OutPack) | Out-Null
Push-Location $repo
try {
  & dart run tool/make_pack.dart --dir $StagingDir --id images-lcm-dreamshaper-v7 --kind image `
    --name 'Images (LCM Dreamshaper v7)' --languages en --engine sdcpp-gguf --license CreativeML-OpenRAIL-M `
    --version 1 --key $KeyPath --out $OutPack
  Assert-Exit 'make_pack'
  $pub = Join-Path ([IO.Path]::GetTempPath()) ('boopack-dev-pub-' + [Guid]::NewGuid().ToString('N') + '.pem')
  try {
    & openssl pkey -in $KeyPath -pubout -out $pub
    Assert-Exit 'openssl pubout'
    & dart run tool/make_pack.dart --verify $OutPack --pubkey $pub
    Assert-Exit 'pack verify'
  } finally {
    Remove-Item -Force -ErrorAction SilentlyContinue $pub
  }
} finally {
  Pop-Location
}

$info = Get-Item -LiteralPath $OutPack
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutPack).Hash.ToLower()
Write-Host ''
Write-Host "pack:   $($info.FullName)"
Write-Host "size:   $($info.Length) bytes"
Write-Host "sha256: $hash"
