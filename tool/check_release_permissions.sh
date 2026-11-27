#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Privacy gate: fails if any release APK requests a network permission, or bundles the onnxruntime
# telemetry code (onnxruntime-android 1.29+ ships an HttpClient started by a TelemetryInitializer
# provider; BooBoard pins 1.28.0, see android/app/build.gradle.kts).
# Usage: tool/check_release_permissions.sh build/app/outputs/flutter-apk/*-release.apk
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <release.apk>..." >&2
  exit 2
fi

AAPT2=$(ls -d "${ANDROID_HOME:-$ANDROID_SDK_ROOT}"/build-tools/*/aapt2* | sort -V | tail -n 1)
FORBIDDEN='android.permission.INTERNET|android.permission.ACCESS_NETWORK_STATE|android.permission.ACCESS_WIFI_STATE'
TELEMETRY='ai/onnxruntime/telemetry|TelemetryInitializer'
status=0
for apk in "$@"; do
  if [ ! -f "$apk" ]; then
    echo "FAIL: $apk does not exist" >&2
    status=1
    continue
  fi
  perms=$("$AAPT2" dump permissions "$apk")
  echo "== $apk"
  echo "$perms" | grep -E "uses-permission" || true
  if echo "$perms" | grep -Eq "$FORBIDDEN"; then
    echo "FAIL: $apk requests a network permission" >&2
    status=1
  fi
  if "$AAPT2" dump xmltree --file AndroidManifest.xml "$apk" | grep -Eq "$TELEMETRY"; then
    echo "FAIL: $apk declares the onnxruntime telemetry provider" >&2
    status=1
  fi
  if unzip -p "$apk" 'classes*.dex' | grep -aEq "$TELEMETRY"; then
    echo "FAIL: $apk contains onnxruntime telemetry classes" >&2
    status=1
  fi
done
exit $status
