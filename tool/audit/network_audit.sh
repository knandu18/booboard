#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Network and telemetry audit of release APKs (Wave 5-A). Complements tool/check_release_permissions.sh
# (which is the blocking gate and is not changed here). This script prints more evidence and fails on
# a wider set of network and analytics SDK classes.
#
# Usage: bash tool/audit/network_audit.sh <release.apk>...
#
# FAIL (exit 1): a network or cleartext permission; a network or analytics SDK class in the dex; the
#   telemetry provider; the debug testbed activity; allowBackup, debuggable or usesCleartextTraffic set.
# INFO: JDK network classes that libraries reference (they cannot open a socket without INTERNET);
#   native libraries that reference name-resolution symbols.
#
# Android enforces the INTERNET permission in the kernel: without it, socket() fails for the app, so the
# permission check is the real control. The class scan proves nothing is left that would try.
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <release.apk>..." >&2
  exit 2
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
AAPT2=$(ls -d "$SDK"/build-tools/*/aapt2* | sort -V | tail -n 1)

# Permissions a release may hold (docs/security/threat-model.md). Anything else is a FAIL, including
# every network permission (checked again below so the message is explicit).
ALLOWED_PERMISSIONS='android\.permission\.(VIBRATE|RECORD_AUDIO|USE_BIOMETRIC|USE_FINGERPRINT)|app\.booboard\.keyboard\.[A-Za-z_.]*PERMISSION'
# Network-capable and telemetry families, matched as dex descriptor prefixes.
FAIL_FAMILIES='Lokhttp3/|Lretrofit2/|Lcom/google/firebase/|Lcom/google/android/gms/analytics/|Lcom/google/android/gms/ads/|Lio/sentry/|Lcom/crashlytics/|Lcom/amplitude/|Lcom/mixpanel/|Lcom/appsflyer/|Lcom/segment/analytics/|Lorg/chromium/net/|Lcom/android/volley/|Lai/onnxruntime/telemetry/|TelemetryInitializer'
INFO_FAMILIES='Ljava/net/HttpURLConnection;|Ljava/net/URL;|Ljava/net/Socket;|Ljava/net/DatagramSocket;|Ljavax/net/ssl/|Lcom/google/android/gms/'

status=0
fail() { echo "FAIL: $*" >&2; status=1; }

for apk in "$@"; do
  echo "== $apk"
  if [ ! -f "$apk" ]; then
    fail "$apk does not exist"
    continue
  fi

  # 1. Permissions.
  perms=$("$AAPT2" dump permissions "$apk" | sed -n 's/^uses-permission: name=//p' | tr -d "'" | sort -u)
  echo "permissions:"
  printf '  %s\n' $perms
  for p in $perms; do
    if ! echo "$p" | grep -Eq "^($ALLOWED_PERMISSIONS)\$"; then
      fail "$apk requests $p, which is not in the release allowlist"
    fi
  done
  for p in android.permission.INTERNET android.permission.ACCESS_NETWORK_STATE android.permission.ACCESS_WIFI_STATE; do
    if echo "$perms" | grep -qx "$p"; then fail "$apk requests $p"; fi
  done

  # 2. Manifest flags (aapt2 writes booleans as 0xffffffff for true).
  manifest=$("$AAPT2" dump xmltree --file AndroidManifest.xml "$apk")
  if echo "$manifest" | grep -Eq 'android:allowBackup\(0x01010280\)=\(type 0x12\)0xffffffff'; then
    fail "$apk sets android:allowBackup=true"
  fi
  if echo "$manifest" | grep -Eq 'android:debuggable\(0x0101000f\)=\(type 0x12\)0xffffffff'; then
    fail "$apk is debuggable"
  fi
  if echo "$manifest" | grep -Eq 'android:usesCleartextTraffic\(0x010104ec\)=\(type 0x12\)0xffffffff'; then
    fail "$apk allows cleartext traffic"
  fi
  if echo "$manifest" | grep -q 'testbed'; then
    fail "$apk declares the debug testbed activity"
  fi
  echo "components (E: lines):"
  echo "$manifest" | grep -E '^ +E: (activity|service|receiver|provider)' | sed 's/^ */  /' || true

  # 3. Dex class scan.
  dex=$(mktemp "${TMPDIR:-/tmp}/booboard-dex.XXXXXX")
  unzip -p "$apk" 'classes*.dex' > "$dex" 2>/dev/null || true
  if [ ! -s "$dex" ]; then
    fail "$apk has no classes*.dex"
  fi
  for family in $(echo "$FAIL_FAMILIES" | tr '|' ' '); do
    hits=$(grep -a -o -E -e "${family}[A-Za-z0-9_/\$]*" "$dex" | sort -u || true)
    if [ -n "$hits" ]; then
      fail "$apk contains $family classes: $(echo "$hits" | tr '\n' ' ')"
    fi
  done
  echo "dex references to JDK and library network classes (info):"
  for family in $(echo "$INFO_FAMILIES" | tr '|' ' '); do
    count=$(grep -a -o -E -e "${family}[A-Za-z0-9_/\$]*" "$dex" | wc -l | tr -d ' ' || true)
    if [ "${count:-0}" -gt 0 ]; then echo "  $family $count"; fi
  done
  rm -f "$dex"

  # 4. Native libraries (info only: the Flutter engine contains dart:io socket code).
  echo "native libraries (info):"
  unzip -l "$apk" 'lib/*/*.so' | awk 'NR>3 && /\.so$/ {print $4}' | while IFS= read -r so; do
    n=$(unzip -p "$apk" "$so" | grep -a -c 'getaddrinfo' || true)
    echo "  $so getaddrinfo-refs=$n"
  done
done

if [ "$status" -eq 0 ]; then
  echo "OK: no network permission, no network or telemetry SDK class, no debug flags."
fi
exit $status
