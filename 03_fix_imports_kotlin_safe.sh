#!/usr/bin/env bash
set -euo pipefail
echo "🧩 Step 3: Tambah import expo dalam MainActivity & MainApplication"

for F in \
  android/app/src/main/java/**/MainActivity.kt \
  android/app/src/main/java/**/MainApplication.kt
do
  [ -f "$F" ] || continue
  grep -q 'expo.modules.ReactActivityDelegateWrapper' "$F" || \
    sed -i '1 a\import expo.modules.ReactActivityDelegateWrapper' "$F"
  grep -q 'expo.modules.ReactNativeHostWrapper' "$F" || \
    sed -i '1 a\import expo.modules.ReactNativeHostWrapper' "$F"
  grep -q 'expo.modules.ApplicationLifecycleDispatcher' "$F" || \
    sed -i '1 a\import expo.modules.ApplicationLifecycleDispatcher' "$F"
done
echo "✅ Step 3 selesai"
