# OWNER: Wave 4-A. Stages the dict-zh-rime-ice dictionary pack for signing.
#
# Downloads the pinned rime-ice dictionaries (GPL-3.0) and OpenCC tables (Apache-2.0), checks each file's
# SHA-256, converts them with tool/chinese/build_zh_dict.dart into
#   %USERPROFILE%\.booboard\packs\staging\dict-zh-rime-ice\zh.kdict
#   %USERPROFILE%\.booboard\packs\staging\dict-zh-rime-ice\s2twp.tsv
# then prints the `dart run tool/make_pack.dart` line for the orchestrator to sign. The app never
# downloads anything; the pack is the only way the dictionary reaches the phone.
#
#   powershell -ExecutionPolicy Bypass -File tool/packs/chinese/stage_rime_ice.ps1
#
# Needs curl.exe (Windows 10+), Dart on PATH, and about 100 MB of disk space for the downloads.
# The downloads are cached in %USERPROFILE%\.booboard\packs\cache and reused when their hashes match.

param(
    [string]$Staging = (Join-Path $env:USERPROFILE '.booboard\packs\staging'),
    [string]$Cache = (Join-Path $env:USERPROFILE '.booboard\packs\cache'),
    [int]$GoldenMinWeight = 100000
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $repo

$rimeSha = '927e1cf1d3eeb9bf4be85e3f684dba4dd485b6f6'
$openccSha = 'fae2a0a911c30764e669a7d8b0591cd8e852934a'

# name, directory key, remote path, SHA-256
$files = @(
    @{ Name = 'base.dict.yaml'; Dir = "rime-ice-$($rimeSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/iDvel/rime-ice/$rimeSha/cn_dicts/base.dict.yaml"; Sha = 'c1f07daa4680a437a04169211e4a80b19923fd61cff322753d3ee98a7e1bffc8' },
    @{ Name = 'ext.dict.yaml'; Dir = "rime-ice-$($rimeSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/iDvel/rime-ice/$rimeSha/cn_dicts/ext.dict.yaml"; Sha = 'f713d82f5a3c38bf955fef631353c6bd08c3e1ae6674d7db0c4f286480d760a1' },
    @{ Name = '8105.dict.yaml'; Dir = "rime-ice-$($rimeSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/iDvel/rime-ice/$rimeSha/cn_dicts/8105.dict.yaml"; Sha = '1f9a42b91dea6982baee2551981780271aeffd78876662b9c9f324e56b37b120' },
    @{ Name = 'STPhrases.txt'; Dir = "opencc-$($openccSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/BYVoid/OpenCC/$openccSha/data/dictionary/STPhrases.txt"; Sha = '24d23700f4f3d1860b899aa90896dcc7ec56c535a0b3a246bbf5a7048c7bdeb8' },
    @{ Name = 'STCharacters.txt'; Dir = "opencc-$($openccSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/BYVoid/OpenCC/$openccSha/data/dictionary/STCharacters.txt"; Sha = 'a0ca1601c70648cf48b33c3c6210ccbecc5c7eead4b4c3daf76587ba2c03582b' },
    @{ Name = 'TWPhrases.txt'; Dir = "opencc-$($openccSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/BYVoid/OpenCC/$openccSha/data/dictionary/TWPhrases.txt"; Sha = '4d3f83634d8a02be5fc82def7e6ae418ab2ab501b100952da5ef934460813a41' },
    @{ Name = 'TWVariants.txt'; Dir = "opencc-$($openccSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/BYVoid/OpenCC/$openccSha/data/dictionary/TWVariants.txt"; Sha = '245b94eb5842957e735dd44b7e7d4ff469a3643126cc8fa511adda5281e9cb86' },
    @{ Name = 'LICENSE'; Dir = "rime-ice-$($rimeSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/iDvel/rime-ice/$rimeSha/LICENSE"; Sha = '3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986' },
    @{ Name = 'LICENSE'; Dir = "opencc-$($openccSha.Substring(0,7))"; Url = "https://raw.githubusercontent.com/BYVoid/OpenCC/$openccSha/LICENSE"; Sha = 'b534e465949558eec2597b04f5092b5e161236a68dfbfd04d547592ac3964308' }
)

foreach ($f in $files) {
    $dir = Join-Path $Cache $f.Dir
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $path = Join-Path $dir $f.Name
    $ok = (Test-Path $path) -and ((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant() -eq $f.Sha)
    if (-not $ok) {
        & curl.exe -sL --fail --max-time 600 -o $path $f.Url
        if ($LASTEXITCODE -ne 0) { throw "download failed: $($f.Url)" }
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
        if ($hash -ne $f.Sha) { throw "SHA-256 mismatch for $($f.Name): got $hash" }
    }
    Write-Output "ok  $($f.Name)"
}

$rimeDir = Join-Path $Cache "rime-ice-$($rimeSha.Substring(0,7))"
$openccDir = Join-Path $Cache "opencc-$($openccSha.Substring(0,7))"
$dest = Join-Path $Staging 'dict-zh-rime-ice'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
New-Item -ItemType Directory -Force -Path $dest | Out-Null

& dart run tool/chinese/build_zh_dict.dart --rime $rimeDir --opencc $openccDir --out $dest --golden (Join-Path $repo 'test\engine\lang\chinese\golden_zh.txt') --golden-min-weight $GoldenMinWeight
if ($LASTEXITCODE -ne 0) { throw 'build_zh_dict failed' }

# NOTICE.txt: the sources, the pinned commits and both licence texts travel inside the pack.
$notice = @()
$notice += 'dict-zh-rime-ice: Chinese (Simplified) dictionary for BooBoard, converted from rime-ice and OpenCC.'
$notice += "rime-ice: https://github.com/iDvel/rime-ice (cn_dicts/base, ext, 8105), commit $rimeSha. Licence: GPL-3.0."
$notice += "OpenCC: https://github.com/BYVoid/OpenCC (data/dictionary ST*, TW*), commit $openccSha. Licence: Apache-2.0."
$notice += 'Converted: entries re-encoded into the zh.kdict binary format; OpenCC tables merged into s2twp.tsv.'
$notice += ''
$notice += '----- LICENSE (rime-ice, GPL-3.0) -----'
$notice += (Get-Content -Raw -Encoding UTF8 (Join-Path $rimeDir 'LICENSE'))
$notice += '----- LICENSE (OpenCC, Apache-2.0) -----'
$notice += (Get-Content -Raw -Encoding UTF8 (Join-Path $openccDir 'LICENSE'))
[System.IO.File]::WriteAllText((Join-Path $dest 'NOTICE.txt'), (($notice -join "`n") -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding $false))

$size = (Get-ChildItem -File $dest | Measure-Object -Property Length -Sum).Sum
Write-Output ("dict-zh-rime-ice staged: {0:N1} MB in {1}" -f ($size / 1MB), $dest)
Write-Output ''
Write-Output 'Sign the pack (the orchestrator runs this with the signing key):'
Write-Output "dart run tool/make_pack.dart --dir `"$dest`" --id dict-zh-rime-ice --kind dictionary --name `"Chinese (Simplified) dictionary`" --languages zh --engine rime-ice --license GPL-3.0-or-later --key <signing key .pem> --out build/packs/dict-zh-rime-ice.boopack"
