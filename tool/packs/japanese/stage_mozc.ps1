# SPDX-License-Identifier: GPL-3.0-or-later
#
# OWNER: Wave 4-B (Japanese). Stages the dict-ja-mozc pack folder:
#   1. downloads the Mozc open-source dictionary files at a pinned commit (BSD-3-Clause, see
#      docs/notices/japanese.md),
#   2. converts them with tool/japanese/build_mozc_lexicon.dart (japanese.lex.gz, japanese.conn.gz),
#   3. writes NOTICE.txt into the folder,
#   4. prints the tool/make_pack.dart line. The orchestrator signs the pack (the key is outside the repo).
#
#   powershell -ExecutionPolicy Bypass -File tool/packs/japanese/stage_mozc.ps1
#
# Output folder: %USERPROFILE%\.booboard\packs\staging\dict-ja-mozc
param(
    [string]$Commit = '1527a4cd1217cec4611cd4bc8d46f8c66ea79e6a'
)

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$base = "https://raw.githubusercontent.com/google/mozc/$Commit"
$work = Join-Path $env:TEMP "booboard-mozc-$Commit"
$staging = Join-Path $env:USERPROFILE '.booboard\packs\staging\dict-ja-mozc'

New-Item -ItemType Directory -Force -Path $work | Out-Null
New-Item -ItemType Directory -Force -Path $staging | Out-Null

$files = @(
    'src/data/dictionary_oss/dictionary00.txt',
    'src/data/dictionary_oss/dictionary01.txt',
    'src/data/dictionary_oss/dictionary02.txt',
    'src/data/dictionary_oss/dictionary03.txt',
    'src/data/dictionary_oss/dictionary04.txt',
    'src/data/dictionary_oss/dictionary05.txt',
    'src/data/dictionary_oss/dictionary06.txt',
    'src/data/dictionary_oss/dictionary07.txt',
    'src/data/dictionary_oss/dictionary08.txt',
    'src/data/dictionary_oss/dictionary09.txt',
    'src/data/dictionary_oss/connection_single_column.txt',
    'src/data/dictionary_oss/id.def',
    'src/data/dictionary_oss/README.txt',
    'LICENSE'
)
foreach ($f in $files) {
    $name = Split-Path -Leaf $f
    $dest = Join-Path $work $name
    if (-not (Test-Path $dest)) {
        Write-Host "downloading $name"
        Invoke-WebRequest -Uri "$base/$f" -OutFile $dest -UseBasicParsing
    }
}

Push-Location $repo
try {
    & dart run tool/japanese/build_mozc_lexicon.dart --src $work --out $staging
    if ($LASTEXITCODE -ne 0) { throw 'build_mozc_lexicon.dart failed' }
} finally {
    Pop-Location
}

# NOTICE.txt: the source, the pinned commit, and both licence texts the Mozc dictionary carries.
$notice = @()
$notice += 'dict-ja-mozc: Japanese dictionary for BooBoard, converted from the Mozc open-source dictionary.'
$notice += "Source: https://github.com/google/mozc (src/data/dictionary_oss), commit $Commit"
$notice += 'Licence: BSD-3-Clause (Mozc), with the IPAdic-derived terms and the Okinawa dictionary notice in the README below.'
$notice += 'Converted: readings folded to hiragana, entries with other characters dropped, connection matrix kept whole.'
$notice += ''
$notice += '----- LICENSE (Mozc) -----'
$notice += Get-Content -Raw -Path (Join-Path $work 'LICENSE')
$notice += ''
$notice += '----- README (dictionary_oss, IPAdic and Okinawa dictionary terms) -----'
$notice += Get-Content -Raw -Path (Join-Path $work 'README.txt')
Set-Content -Path (Join-Path $staging 'NOTICE.txt') -Value ($notice -join "`n") -Encoding utf8

Write-Host ''
Write-Host "Staged: $staging"
Get-ChildItem $staging | ForEach-Object { Write-Host ("  {0}  {1} bytes" -f $_.Name, $_.Length) }
Write-Host ''
Write-Host 'Pack line (the orchestrator signs it):'
Write-Host "dart run tool/make_pack.dart --dir `"$staging`" --id dict-ja-mozc --kind dictionary --name `"Japanese dictionary (Mozc)`" --languages ja --engine mozc --license BSD-3-Clause --version 1 --key <signing key .pem> --out build/packs/dict-ja-mozc.boopack"
