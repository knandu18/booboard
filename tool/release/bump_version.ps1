# SPDX-License-Identifier: GPL-3.0-or-later
#
# Sets the release version in pubspec.yaml (the single source of versionName and versionCode; see
# android/app/build.gradle.kts). Keeps pubspec.yaml's line endings (it is CRLF).
#
#   powershell -ExecutionPolicy Bypass -File tool\release\bump_version.ps1 -Name 1.0.1 -Build 2
#
# -Name is the user-visible version (versionName). -Build is the integer after '+' (versionCode).
# The build number must increase on every published release, because Android refuses downgrades
# and F-Droid orders builds by it. The script refuses a build number that is not greater than the
# current one. It does not commit, tag or publish.
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][int]$Build,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($Name -notmatch '^\d+\.\d+\.\d+$') { throw "'$Name' must look like 1.2.3" }
if ($Build -lt 1) { throw 'The build number must be at least 1' }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pubspec = Join-Path $repoRoot 'pubspec.yaml'
$text = [System.IO.File]::ReadAllText($pubspec)

# [^\r\n]* keeps the CR of a CRLF line ending outside the match.
$pattern = '(?m)^version:[ \t]*([0-9.]+)\+([0-9]+)[^\r\n]*'
$match = [regex]::Match($text, $pattern)
if (-not $match.Success) { throw 'pubspec.yaml has no "version: x.y.z+n" line' }

$currentBuild = [int]$match.Groups[2].Value
if ($Build -le $currentBuild) {
    throw "Build $Build is not greater than the current build $currentBuild. Android refuses downgrades."
}

$replacement = "version: $Name+$Build"
$newText = [regex]::Replace($text, $pattern, $replacement)
Write-Host "pubspec.yaml: $($match.Value.TrimEnd("`r")) -> $replacement"

if ($DryRun) {
    Write-Host 'Dry run: nothing written.'
} else {
    [System.IO.File]::WriteAllText($pubspec, $newText, $Utf8NoBom)
    Write-Host 'Written. Next: add fastlane/metadata/android/*/changelogs/<build>.txt for each locale, then commit.'
}
