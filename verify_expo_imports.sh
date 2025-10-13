#!/usr/bin/env bash
set -euo pipefail

echo "🔎 Kira fail .kt sasaran:"
TARGETS=$(cat <<EOF
android/app/src/main/java/com/redsulphur/forensiknama/MainActivity.kt
android/app/src/main/java/com/redsulphur/forensiknama/MainApplication.kt
EOF
)
echo "$TARGETS" | awk '{print " - "$0}'

echo ""
echo "✅ Wujud?"
MISSING=0
while read -r f; do
  [[ -z "$f" ]] && continue
  if [[ -f "$f" ]]; then echo "  ✔ $f"; else echo "  ✖ $f (missing)"; MISSING=1; fi
done <<< "$TARGETS"

echo ""
echo "🔎 Grep import expo wrapper/lifecycle:"
grep -R --line-number --include='*.kt' -E \
'ReactActivityDelegateWrapper|ReactNativeHostWrapper|ApplicationLifecycleDispatcher' \
android/app/src/main/java || true

echo ""
echo "🔎 Cek settings.gradle repos+includes:"
grep -nE 'pluginManagement|gradlePluginPortal|RepositoriesMode|includeBuild' android/settings.gradle || true

echo ""
if [[ "$MISSING" -eq 0 ]]; then
  echo "✅ VERIFY OK: semua fail & import nampak betul di peringkat file."
  exit 0
else
  echo "❌ VERIFY FAIL: ada fail yang hilang."
  exit 1
fi
