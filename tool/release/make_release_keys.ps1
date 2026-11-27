# SPDX-License-Identifier: GPL-3.0-or-later
#
# Generates BooBoard's release signing material OUTSIDE the repository. Run it once, on the release
# machine, after the Wave 5 merge. It never runs against the real folder in development:
# tests pass -OutDir pointing at a throwaway folder.
#
#   powershell -ExecutionPolicy Bypass -File tool\release\make_release_keys.ps1
#   powershell -ExecutionPolicy Bypass -File tool\release\make_release_keys.ps1 -OutDir $env:TEMP\booboard-keytest
#
# Creates, in OutDir (default %USERPROFILE%\.booboard\release):
#   booboard-release.p12          upload/release keystore: RSA 4096, PKCS#12, valid 30 years
#   release-keystore.password  random 256-bit password, one line; the store and key password are the same
#                              (PKCS#12 keystores keep one password)
#   key.properties             android\key.properties content (absolute storeFile, forward slashes)
#   pack-release.pem           ECDSA P-256 private key that signs model packs (SEC1 PEM, as tool/make_pack.dart expects)
#   pack-release.pub.b64       its public key, base64 X.509 SubjectPublicKeyInfo DER: the value PackKeys.kt embeds
#
# Prints SHA-256 fingerprints and the next steps. It never prints a password or a private key.
# It refuses to overwrite anything, and it refuses an OutDir inside the repository.
param(
    [string]$OutDir = (Join-Path $env:USERPROFILE '.booboard\release'),
    [string]$KeyAlias = 'booboard-release'
)

$ErrorActionPreference = 'Stop'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Step([string]$Text) { Write-Host "==> $Text" }

function Find-Tool([string]$Name, [string[]]$Fallbacks) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($candidate in $Fallbacks) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }
    throw "$Name not found. Install a JDK (keytool) or Git for Windows (openssl), or add it to PATH."
}

function Restrict-Acl([string]$Path) {
    # Only the current user may read or write. Inheritance is removed. Folders pass the
    # inheritance flags to their children; a file gets a plain Full Control entry.
    $account = "$($env:USERDOMAIN)\$($env:USERNAME)"
    $grant = if (Test-Path -PathType Container $Path) { "${account}:(OI)(CI)F" } else { "${account}:F" }
    & icacls $Path /inheritance:r /grant:r $grant | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls could not restrict $Path" }
}

function Get-Sha256Hex([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('X2') }) -join ':') }
    finally { $sha.Dispose() }
}

# --- Locate tools and check the target folder -------------------------------------------------------

$keytool = Find-Tool 'keytool' @(
    $(if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\keytool.exe' }),
    'C:\Program Files\Microsoft\jdk-17*\bin\keytool.exe'
)
$openssl = Find-Tool 'openssl' @(
    'C:\Program Files\Git\usr\bin\openssl.exe',
    'C:\Program Files\Git\mingw64\bin\openssl.exe'
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path.TrimEnd('\')
$outFull = [System.IO.Path]::GetFullPath($OutDir).TrimEnd('\')
if ($outFull.StartsWith($repoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase) -or $outFull -eq $repoRoot) {
    throw "Refusing to write keys inside the repository ($repoRoot). Choose a folder outside it."
}

$keystore = Join-Path $outFull 'booboard-release.p12'
$passwordFile = Join-Path $outFull 'release-keystore.password'
$keyProperties = Join-Path $outFull 'key.properties'
$packPem = Join-Path $outFull 'pack-release.pem'
$packPub = Join-Path $outFull 'pack-release.pub.b64'
$outputs = @($keystore, $passwordFile, $keyProperties, $packPem, $packPub)

$existing = @($outputs | Where-Object { Test-Path $_ })
if ($existing.Count -gt 0) {
    throw "Refusing to overwrite existing files: $($existing -join ', '). Move them away first, or pick another -OutDir."
}

New-Item -ItemType Directory -Force -Path $outFull | Out-Null
Restrict-Acl $outFull

# --- Password (random, never printed) --------------------------------------------------------------

Write-Step "Generating the keystore password (not printed)"
$randomBytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($randomBytes) } finally { $rng.Dispose() }
$password = -join ($randomBytes | ForEach-Object { $_.ToString('x2') })
[System.IO.File]::WriteAllText($passwordFile, $password, $Utf8NoBom)
Restrict-Acl $passwordFile

# --- Upload / release keystore ---------------------------------------------------------------------

Write-Step "Creating the RSA 4096 release keystore (valid 30 years)"
& $keytool -genkeypair -noprompt `
    -alias $KeyAlias -keyalg RSA -keysize 4096 -sigalg SHA256withRSA -validity 10950 `
    -dname 'CN=BooBoard release key, O=BooBoard project' `
    -storetype PKCS12 -keystore $keystore `
    -storepass:file $passwordFile -keypass:file $passwordFile
if ($LASTEXITCODE -ne 0) { throw 'keytool failed to create the keystore' }
Restrict-Acl $keystore

# --- Pack-signing key (ECDSA P-256) ---------------------------------------------------------------

Write-Step "Creating the ECDSA P-256 pack-signing key"
& $openssl ecparam -name prime256v1 -genkey -noout -out $packPem
if ($LASTEXITCODE -ne 0) { throw 'openssl failed to create the pack key' }
Restrict-Acl $packPem

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('booboard-packkey-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    $packDer = Join-Path $tmp 'pub.der'
    & $openssl ec -in $packPem -pubout -outform DER -out $packDer
    if ($LASTEXITCODE -ne 0) { throw 'openssl failed to export the public key' }
    $der = [System.IO.File]::ReadAllBytes($packDer)
    [System.IO.File]::WriteAllText($packPub, [Convert]::ToBase64String($der), $Utf8NoBom)

    # Self-test: sign with the private key and verify with the published public key.
    $msg = Join-Path $tmp 'msg.bin'
    $sig = Join-Path $tmp 'msg.sig'
    $pubPem = Join-Path $tmp 'pub.pem'
    [System.IO.File]::WriteAllBytes($msg, [byte[]](1..64))
    & $openssl dgst -sha256 -sign $packPem -out $sig $msg
    if ($LASTEXITCODE -ne 0) { throw 'self-test: signing failed' }
    & $openssl pkey -pubin -inform DER -in $packDer -out $pubPem
    if ($LASTEXITCODE -ne 0) { throw 'self-test: public key conversion failed' }
    & $openssl dgst -sha256 -verify $pubPem -signature $sig $msg
    if ($LASTEXITCODE -ne 0) { throw 'self-test: verification failed' }
    $packFingerprint = Get-Sha256Hex $der
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

# --- key.properties (Java properties: forward slashes, no escaping needed) -------------------------

$storeForProps = $keystore.Replace('\', '/')
$props = @(
    "storeFile=$storeForProps",
    "storePassword=$password",
    "keyAlias=$KeyAlias",
    "keyPassword=$password"
) -join "`n"
[System.IO.File]::WriteAllText($keyProperties, $props + "`n", $Utf8NoBom)
Restrict-Acl $keyProperties
$password = $null

# --- Fingerprints ----------------------------------------------------------------------------------

Write-Step "Keystore certificate fingerprints"
$listing = & $keytool -list -v -keystore $keystore -storetype PKCS12 -storepass:file $passwordFile -alias $KeyAlias
$sha256Line = $listing | Where-Object { $_ -match 'SHA256:' } | Select-Object -First 1
Write-Host $sha256Line.Trim()

Write-Host ''
Write-Host "Pack-signing public key SHA-256 (DER): $packFingerprint"
Write-Host ''
Write-Host "Created in: $outFull"
Write-Host '  booboard-release.p12, release-keystore.password, key.properties, pack-release.pem, pack-release.pub.b64'
Write-Host ''
Write-Host 'Next steps (user):'
Write-Host '  1. Back up the whole folder to TWO offline places (for example two encrypted USB drives). Not the cloud, not the repo.'
Write-Host '     Losing the keystore means no update can ever reach existing installs; losing the pack key means packs cannot be re-signed.'
Write-Host '  2. Store the keystore password in a password manager as well. Do not paste it into chat or commit it.'
Write-Host '  3. Give the orchestrator (or set yourself) BOOBOARD_KEYSTORE_PATH, BOOBOARD_KEY_ALIAS, BOOBOARD_KEYSTORE_PASSWORD, BOOBOARD_KEY_PASSWORD.'
Write-Host '     Or copy key.properties to android\key.properties (git-ignored) for local release builds.'
Write-Host '  4. Orchestrator: put the contents of pack-release.pub.b64 into PackKeys.kt as the trusted release key, and re-sign packs.'
Write-Host '  5. For the GitHub secrets (release.yml), see docs/release/RELEASING.md, "Secrets".'
