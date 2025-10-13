#!/usr/bin/env bash
set -euo pipefail

APP_GRADLE="android/app/build.gradle"

if [ ! -f "$APP_GRADLE" ]; then
  echo "❌ $APP_GRADLE tak jumpa. Pastikan android/ wujud (run: npx expo prebuild --platform android)."
  exit 1
fi

echo "➡️  Patch $APP_GRADLE: tambah expo-modules-core kalau tiada…"

# Tambah dependency expo-modules-core dalam block dependencies { ... } jika belum ada
if ! grep -q 'expo.modules:expo-modules-core' "$APP_GRADLE"; then
  # sisip line sebelum penutup curly pertama selepas 'dependencies {'
  awk '
    BEGIN{added=0}
    /dependencies[[:space:]]*\{/{
      print; print "    implementation(\"expo.modules:expo-modules-core\")"; added=1; next
    }
    {print}
    END{
      if(!added) {
        print "\ndependencies {"
        print "    implementation(\"expo.modules:expo-modules-core\")"
        print "}"
      }
    }
  ' "$APP_GRADLE" > "$APP_GRADLE.tmp" && mv "$APP_GRADLE.tmp" "$APP_GRADLE"
  echo "✅ Ditambah: implementation(\"expo.modules:expo-modules-core\")"
else
  echo "✅ Sudah ada: expo-modules-core"
fi

echo "➡️  Semak dependency pada classpath…"
( cd android && ./gradlew :app:dependencies --configuration releaseCompileClasspath > /tmp/dep.txt )
if grep -q 'expo-modules-core' /tmp/dep.txt; then
  echo "✅ Dikesan dalam releaseCompileClasspath:"
  grep -n 'expo-modules-core' /tmp/dep.txt | head -3
else
  echo "❌ Masih belum nampak expo-modules-core pada classpath. Sila semak settings.gradle & autolinking."
  echo "   Tip: pastikan settings.gradle ada expo autolinking plugin."
fi

echo "➡️  (Opsyen) Pastikan import di Kotlin files ada…"
for F in \
  android/app/src/main/java/**/MainActivity.kt \
  android/app/src/main/java/**/MainApplication.kt
do
  [ -f "$F" ] || continue
  # Import untuk Expo
  if ! grep -q 'import expo.modules.ReactActivityDelegateWrapper' "$F"; then
    sed -i.bak '1 a\import expo.modules.ReactActivityDelegateWrapper' "$F" || true
  fi
  if ! grep -q 'import expo.modules.ReactNativeHostWrapper' "$F"; then
    sed -i.bak '1 a\import expo.modules.ReactNativeHostWrapper' "$F" || true
  fi
  if ! grep -q 'import expo.modules.ApplicationLifecycleDispatcher' "$F"; then
    sed -i.bak '1 a\import expo.modules.ApplicationLifecycleDispatcher' "$F" || true
  fi
done
echo "✅ Import Kotlin disemak."

echo "➡️  Build semula (release):"
echo "   cd android && ./gradlew assembleRelease"
