#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Repository hygiene gate (CI job "hygiene"). Fails when the tracked files contain:
#   - signing or key material by file name (.jks, .keystore, .pem, .p12, .pfx, key.properties)
#   - BooBoard data that must never be committed (.boobackup, .boopack, .kdict dictionaries are
#     allowed only under assets/, so they are not listed here)
#   - a private key in the text of any file
#   - any file over 5 MB
#
# Checks the files Git tracks (the same set a clone gets). Run from the repository root:
#   bash tool/audit/repo_hygiene.sh
set -euo pipefail

LIMIT_BYTES=$((5 * 1024 * 1024))
NAME_RE='\.(jks|keystore|pem|p12|pfx|boobackup|boopack)$|(^|/)key\.properties$'
KEY_RE='-----BEGIN ([A-Z0-9]+ )?PRIVATE KEY-----'

status=0
files=$(git ls-files)

bad_names=$(printf '%s\n' "$files" | grep -E -i "$NAME_RE" || true)
if [ -n "$bad_names" ]; then
  echo "FAIL: key material or BooBoard data files are tracked:" >&2
  printf '  %s\n' $bad_names >&2
  status=1
fi

big=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  size=$(wc -c < "$f")
  if [ "$size" -gt "$LIMIT_BYTES" ]; then
    big="$big $f ($size bytes)"
  fi
done <<EOF
$files
EOF
if [ -n "$big" ]; then
  echo "FAIL: files over 5 MB are tracked:$big" >&2
  status=1
fi

keys=$(printf '%s\n' "$files" | while IFS= read -r f; do
  [ -f "$f" ] || continue
  if grep -I -q -E -e "$KEY_RE" "$f"; then echo "$f"; fi
done)
if [ -n "$keys" ]; then
  echo "FAIL: private key blocks found in tracked files:" >&2
  printf '  %s\n' $keys >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  count=$(printf '%s\n' "$files" | grep -c . || true)
  echo "OK: $count tracked files, no key material, no BooBoard data files, none over 5 MB."
fi
exit $status
