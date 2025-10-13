#!/usr/bin/env bash
set -euo pipefail

# cari fail Kotlin
ACT=$(ls android/app/src/main/java/**/MainActivity.kt 2>/dev/null | head -n1 || true)
APP=$(ls android/app/src/main/java/**/MainApplication.kt 2>/dev/null | head -n1 || true)

[[ -z "${ACT}" || -z "${APP}" ]] && { echo "❌ MainActivity.kt/MainApplication.kt tak jumpa"; exit 1; }

echo "→ Patch imports untuk:"
echo "   - $ACT"
echo "   - $APP"

# helper: selit import selepas baris 'package ...'
ins_import() {
  local file="$1"; shift
  local import_line
  for import_line in "$@"; do
    grep -qF "$import_line" "$file" || \
      sed -i '0,/^package[[:space:]].*$/s//&\
'"$import_line"'/' "$file"
  done
}

# MainActivity: perlukan ReactActivityDelegateWrapper
ins_import "$ACT" \
"import expo.modules.ReactActivityDelegateWrapper"

# MainApplication: perlukan dua import ini
ins_import "$APP" \
"import expo.modules.ApplicationLifecycleDispatcher" \
"import expo.modules.ReactNativeHostWrapper"

echo "✅ Imports ditambah (jika belum ada)."
