#!/usr/bin/env bash
# Recompute the SHA-256 of every file listed in MANIFEST.sha256 and compare.
# Exit 0 if every file matches. Exit 1 on any mismatch or missing file.
# Exit 2 if the manifest or a hashing tool is missing or the manifest is malformed.
set -u
cd "$(dirname "$0")/.." || exit 2
MANIFEST="MANIFEST.sha256"
[ -f "$MANIFEST" ] || { echo "ERROR: $MANIFEST not found" >&2; exit 2; }

if command -v sha256sum >/dev/null 2>&1; then
  hash() { sha256sum -- "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  hash() { shasum -a 256 -- "$1" | awk '{print $1}'; }
else
  echo "ERROR: need sha256sum or shasum" >&2; exit 2
fi

fail=0; n=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|'#'*) continue ;; esac
  expected=${line%% *}
  file=${line#* }; file=${file# }; file=${file#\*}
  if ! [[ "$expected" =~ ^[0-9a-f]{64}$ ]] || [ -z "$file" ]; then
    echo "MALFORMED: $line" >&2; exit 2
  fi
  n=$((n+1))
  if [ ! -f "$file" ]; then
    echo "MISSING   $file"; fail=1; continue
  fi
  actual=$(hash "$file")
  if [ "$actual" = "$expected" ]; then
    echo "OK        $file  $actual"
  else
    echo "MISMATCH  $file"; echo "  expected $expected"; echo "  actual   $actual"; fail=1
  fi
done < "$MANIFEST"

if [ "$n" -eq 0 ]; then echo "ERROR: manifest lists no files" >&2; exit 2; fi
if [ "$fail" -ne 0 ]; then echo "FAILED: one or more files did not verify"; exit 1; fi
echo "PASSED: $n/$n files verified"
