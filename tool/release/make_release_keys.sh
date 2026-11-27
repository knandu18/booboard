#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# POSIX twin of make_release_keys.ps1 (Linux, macOS, Git Bash). Same outputs, same refusals.
#   tool/release/make_release_keys.sh [OUT_DIR]        default: $HOME/.booboard/release
# Creates booboard-release.p12, release-keystore.password, key.properties, pack-release.pem and
# pack-release.pub.b64 (base64 SPKI DER, the value PackKeys.kt embeds). Never prints a password or key.
set -euo pipefail

umask 077
ALIAS="${BOOBOARD_KEY_ALIAS_NAME:-booboard-release}"
OUT_DIR="${1:-$HOME/.booboard/release}"

command -v keytool >/dev/null || { echo "keytool not found (install a JDK 17)" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl not found" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$OUT_DIR"
OUT_ABS="$(cd "$OUT_DIR" && pwd)"
case "$OUT_ABS/" in
  "$REPO_ROOT/"*) echo "Refusing to write keys inside the repository ($REPO_ROOT)." >&2; exit 1 ;;
esac

KEYSTORE="$OUT_ABS/booboard-release.p12"
PASSFILE="$OUT_ABS/release-keystore.password"
KEYPROPS="$OUT_ABS/key.properties"
PACK_PEM="$OUT_ABS/pack-release.pem"
PACK_PUB="$OUT_ABS/pack-release.pub.b64"

for f in "$KEYSTORE" "$PASSFILE" "$KEYPROPS" "$PACK_PEM" "$PACK_PUB"; do
  if [ -e "$f" ]; then
    echo "Refusing to overwrite existing $f. Move it away first, or pick another OUT_DIR." >&2
    exit 1
  fi
done

echo "==> Generating the keystore password (not printed)"
# 32 random bytes as 64 hex characters: no quoting problems in key.properties or keytool.
openssl rand -hex 32 | tr -d '\n' > "$PASSFILE"
chmod 600 "$PASSFILE"

echo "==> Creating the RSA 4096 release keystore (valid 30 years)"
keytool -genkeypair -noprompt \
  -alias "$ALIAS" -keyalg RSA -keysize 4096 -sigalg SHA256withRSA -validity 10950 \
  -dname 'CN=BooBoard release key, O=BooBoard project' \
  -storetype PKCS12 -keystore "$KEYSTORE" \
  -storepass:file "$PASSFILE" -keypass:file "$PASSFILE"
chmod 600 "$KEYSTORE"

echo "==> Creating the ECDSA P-256 pack-signing key"
openssl ecparam -name prime256v1 -genkey -noout -out "$PACK_PEM"
chmod 600 "$PACK_PEM"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
openssl ec -in "$PACK_PEM" -pubout -outform DER -out "$TMP/pub.der" 2>/dev/null
base64 < "$TMP/pub.der" | tr -d '\n' > "$PACK_PUB"
# Self-test: sign with the private key, verify with the published public key.
head -c 64 /dev/urandom > "$TMP/msg.bin"
openssl dgst -sha256 -sign "$PACK_PEM" -out "$TMP/msg.sig" "$TMP/msg.bin"
openssl pkey -pubin -inform DER -in "$TMP/pub.der" -out "$TMP/pub.pem"
openssl dgst -sha256 -verify "$TMP/pub.pem" -signature "$TMP/msg.sig" "$TMP/msg.bin" >/dev/null

# key.properties: forward slashes so Java properties need no escaping.
STORE_FOR_PROPS="${KEYSTORE//\\//}"
PASS="$(cat "$PASSFILE")"
printf 'storeFile=%s\nstorePassword=%s\nkeyAlias=%s\nkeyPassword=%s\n' \
  "$STORE_FOR_PROPS" "$PASS" "$ALIAS" "$PASS" > "$KEYPROPS"
chmod 600 "$KEYPROPS"
PASS=""

echo "==> Keystore certificate fingerprint"
keytool -list -v -keystore "$KEYSTORE" -storetype PKCS12 -storepass:file "$PASSFILE" -alias "$ALIAS" \
  | grep 'SHA256:' | head -n 1
echo "Pack-signing public key SHA-256 (DER): $(openssl dgst -sha256 -hex < "$TMP/pub.der" | sed 's/.*= //')"
echo
echo "Created in: $OUT_ABS"
echo "Next steps: back up the folder to two offline places; keep the password in a password manager;"
echo "see tool/release/make_release_keys.ps1 for the rest (same steps)."
