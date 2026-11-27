# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copies the signed store packs into the Play asset pack modules (android/asset_packs/<module>/src/main/assets/).
# OWNER: Wave 5-C. The copies are build inputs: they are gitignored and never committed.
#
#   powershell -ExecutionPolicy Bypass -File tool/packs/copy_asset_packs.ps1
#   powershell -ExecutionPolicy Bypass -File tool/packs/copy_asset_packs.ps1 -PacksDir D:\packs\signed -PubKey D:\keys\release-public.pem
#
# -PacksDir defaults to %USERPROFILE%\.booboard\packs\signed (outside the repository). With -PubKey, each pack is
# checked with tool/make_pack.dart --verify before it is copied; the build stops on the first failure.
param(
    [string]$PacksDir = (Join-Path $env:USERPROFILE '.booboard\packs\signed'),
    [string]$PubKey = ''
)

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')

# Pack id -> Gradle module (asset pack name). Keep in step with StoreCatalog in PackSource.kt.
$map = [ordered]@{
    'dict-zh-rime-ice'   = 'pack_dict_zh'
    'dict-ja-mozc'       = 'pack_dict_ja'
    'translate-en-es'    = 'pack_translate_en_es'
}

foreach ($id in $map.Keys) {
    $src = Join-Path $PacksDir "$id.boopack"
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        throw "Missing $src. Build and sign the pack first (tool/make_pack.dart), or pass -PacksDir."
    }
    if ($PubKey -ne '') {
        & dart run (Join-Path $repo 'tool\make_pack.dart') --verify $src --pubkey $PubKey
        if ($LASTEXITCODE -ne 0) { throw "Pack $id failed verification. Nothing was copied for it." }
    }
    $dest = Join-Path $repo "android\asset_packs\$($map[$id])\src\main\assets"
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest "$id.boopack") -Force
    $size = (Get-Item -LiteralPath $src).Length
    Write-Output ("copied {0} -> {1} ({2:N1} MB)" -f $id, $map[$id], ($size / 1MB))
}
