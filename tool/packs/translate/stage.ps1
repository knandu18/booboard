# Stages the 12 translation model packs (English <-> es, fr, de, pt, hi, ru) for signing.
#
# Downloads the pinned ONNX exports listed in models.json (Hugging Face, Xenova conversions of the
# Helsinki-NLP OPUS-MT models), checks every file's SHA-256, and lays each pack out as
#   build/packs/staging/translate-<from>-<to>/model/{encoder.onnx, decoder.onnx, source.spm, vocab.json, config.json}
# then prints the `dart run tool/make_pack.dart` command for it. The orchestrator signs the packs; the app
# never downloads anything. Downloads are cached in build/packs/cache.
#
#   powershell -ExecutionPolicy Bypass -File tool/packs/translate/stage.ps1
#   powershell -ExecutionPolicy Bypass -File tool/packs/translate/stage.ps1 -Only en-es,pt-en
#
# Needs curl.exe (Windows 10+) and about 1.4 GB of disk space for all 12 directions.

param(
    [string[]]$Only = @(),
    [string]$Staging = 'build/packs/staging',
    [string]$Cache = 'build/packs/cache'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $repo

$manifest = Get-Content -Raw -Encoding UTF8 'tool/packs/translate/models.json' | ConvertFrom-Json
$utf8 = New-Object System.Text.UTF8Encoding($false)
$commands = @()

foreach ($pack in $manifest.packs) {
    $key = "$($pack.from)-$($pack.to)"
    if ($Only.Count -gt 0 -and $Only -notcontains $key) { continue }

    $dest = Join-Path $Staging "translate-$key"
    $model = Join-Path $dest 'model'
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    New-Item -ItemType Directory -Force $model | Out-Null

    foreach ($file in $pack.files) {
        $cached = Join-Path $Cache ("$($pack.repo)/$($file.remote)" -replace '/', '\')
        $ok = (Test-Path $cached) -and ((Get-Item $cached).Length -eq $file.size)
        if (-not $ok) {
            New-Item -ItemType Directory -Force (Split-Path -Parent $cached) | Out-Null
            $url = "https://huggingface.co/$($pack.repo)/resolve/$($pack.revision)/$($file.remote)"
            & curl.exe -L --fail --silent --show-error -o $cached $url
            if ($LASTEXITCODE -ne 0) { throw "download failed: $url" }
        }
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $cached).Hash.ToLowerInvariant()
        if ($hash -ne $file.sha256) { throw "SHA-256 mismatch for $($pack.repo)/$($file.remote): got $hash" }
        Copy-Item -LiteralPath $cached -Destination (Join-Path $dest $file.local) -Force
    }

    $config = [ordered]@{
        pad_id = $pack.config.pad_id
        eos_id = $pack.config.eos_id
        unk_id = $pack.config.unk_id
        decoder_start_id = $pack.config.decoder_start_id
        target_token = $pack.config.target_token
        max_length_factor = $pack.config.max_length_factor
        max_extra = $pack.config.max_extra
    }
    [System.IO.File]::WriteAllText((Join-Path $model 'config.json'), ($config | ConvertTo-Json), $utf8)

    $size = (Get-ChildItem -Recurse -File $dest | Measure-Object -Property Length -Sum).Sum
    Write-Output ("{0}: {1:N1} MB staged" -f $key, ($size / 1MB))

    $commands += "dart run tool/make_pack.dart --dir `"$dest`" --id $($pack.id) --kind translation " +
        "--name `"$($pack.name)`" --languages $($pack.from),$($pack.to) --engine opus-mt-onnx " +
        "--license $($pack.license) --key <signing key .pem> --out build/packs/$($pack.id).boopack"
}

Write-Output ''
Write-Output 'Sign each pack (the orchestrator runs these with the signing key):'
$commands | ForEach-Object { Write-Output $_ }
