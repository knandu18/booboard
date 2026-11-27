# SPDX-License-Identifier: GPL-3.0-or-later
#
# Changes BooBoard's applicationId everywhere it is named. Run once, at the very end of the release work,
# when the GitHub username is known (io.github.<username>.booboard). The Kotlin namespace and package
# (app.booboard.keyboard) do NOT change: the applicationId and the namespace may differ in Android.
#
#   powershell -ExecutionPolicy Bypass -File tool\release\set_application_id.ps1 io.github.exampleuser.booboard -DryRun
#   powershell -ExecutionPolicy Bypass -File tool\release\set_application_id.ps1 io.github.exampleuser.booboard
#
# Places it changes (the list also appears in docs/release/RELEASING.md):
#   1. android/app/build.gradle.kts        the single constant booboardApplicationId
#   2. tool/adb_ime.ps1                    $script:Pkg (the IME component is derived from it)
#   3. tool/bench/device_bench.ps1         -Package default
#   4. metadata/<old id>.yml               renamed to metadata/<new id>.yml, and its mentions
#   5. docs/release/**/*.md                every mention of the old id, except lines that talk about the
#                                          namespace or the Kotlin package (those lines are left alone)
# It does NOT change: Kotlin sources, method.xml, pigeons, tests (they use the constant names, not the
# id), and the About source link. Set BOOBOARD_SOURCE_URL for build_release.ps1 by hand (RELEASING.md).
# Line endings are preserved: the script edits text with exact replacements and never rewrites a whole
# line it does not touch.
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$NewId,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($NewId -notmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') {
    throw "'$NewId' is not a valid Android application id (lowercase segments separated by dots)."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repoRoot

$gradlePath = 'android\app\build.gradle.kts'
$gradleText = [System.IO.File]::ReadAllText((Join-Path $repoRoot $gradlePath))
$match = [regex]::Match($gradleText, 'val booboardApplicationId = "([^"]+)"')
if (-not $match.Success) { throw "Cannot find 'val booboardApplicationId' in $gradlePath." }
$oldId = $match.Groups[1].Value
if ($oldId -eq $NewId) { Write-Host "The applicationId is already $NewId. Nothing to do."; return }

$changed = New-Object System.Collections.Generic.List[string]

function Update-File([string]$RelativePath, [scriptblock]$Transform) {
    $full = Join-Path $repoRoot $RelativePath
    $before = [System.IO.File]::ReadAllText($full)
    $after = & $Transform $before
    if ($after -ne $before) {
        if (-not $DryRun) { [System.IO.File]::WriteAllText($full, $after, $Utf8NoBom) }
        $script:changed.Add($RelativePath)
    }
}

# 1. Gradle constant (the only value the build reads).
Update-File $gradlePath {
    param($t) $t.Replace("val booboardApplicationId = `"$oldId`"", "val booboardApplicationId = `"$NewId`"")
}

# 2. adb helpers (the IME component id is derived from the package).
Update-File 'tool\adb_ime.ps1' {
    param($t) [regex]::Replace($t, "(\`$script:Pkg\s*=\s*')$([regex]::Escape($oldId))'", "`${1}$NewId'")
}

# 3. Device benchmark default package.
Update-File 'tool\bench\device_bench.ps1' {
    param($t) [regex]::Replace($t, "(\[string\]\`$Package\s*=\s*')$([regex]::Escape($oldId))'", "`${1}$NewId'")
}

# 4. F-Droid recipe: the file name is the application id.
$oldRecipe = "metadata\$oldId.yml"
$newRecipe = "metadata\$NewId.yml"
if (Test-Path (Join-Path $repoRoot $oldRecipe)) {
    Update-File $oldRecipe { param($t) $t.Replace($oldId, $NewId) }
    if (-not $DryRun) { Move-Item -LiteralPath (Join-Path $repoRoot $oldRecipe) -Destination (Join-Path $repoRoot $newRecipe) }
    $changed.Add("$oldRecipe -> $newRecipe")
}

# 5. Release docs: replace the id on lines that are about the applicationId, not the namespace.
Get-ChildItem -Path (Join-Path $repoRoot 'docs\release') -Filter *.md -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($repoRoot.Length + 1)
    Update-File $rel {
        param($t)
        $lines = $t -split "`n", -1
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]
            if ($line.Contains($oldId) -and $line -notmatch 'namespace|Kotlin package') {
                $lines[$i] = $line.Replace($oldId, $NewId)
            }
        }
        $lines -join "`n"
    }
}

Write-Host "applicationId: $oldId -> $NewId"
if ($DryRun) { Write-Host 'Dry run. Would change:' } else { Write-Host 'Changed:' }
$changed | ForEach-Object { Write-Host "  $_" }
Write-Host ''
Write-Host 'Not changed by this script, check by hand:'
Write-Host '  - Set BOOBOARD_SOURCE_URL (the About source link) for build_release.ps1.'
Write-Host '  - Re-run: flutter test test/release (the consistency test reads the new id).'
Write-Host '  - Rebuild both flavours and run the permission gate; the install id changes, so existing installs are separate apps.'
