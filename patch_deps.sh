#!/usr/bin/env bash
set -euo pipefail
APP_GRADLE=android/app/build.gradle

# Pastikan blok dependencies wujud
grep -q '^dependencies\s*{' "$APP_GRADLE" || {
  printf '\n\ndependencies {\n}\n' >> "$APP_GRADLE"
}

# Tambah expo-modules-core kalau tiada
grep -q 'expo.modules:expo-modules-core' "$APP_GRADLE" || \
  gawk -i inplace '
    BEGIN{added=0}
    {print}
    /^dependencies\s*{/ && !added {print "    implementation(\"expo.modules:expo-modules-core\")"; added=1}
  ' "$APP_GRADLE"

# Tambah react-android kalau tiada (sesuai RN 0.74)
grep -q 'com.facebook.react:react-android' "$APP_GRADLE" || \
  gawk -i inplace '
    BEGIN{added=0}
    {print}
    /^dependencies\s*{/ && !added {print "    implementation(\"com.facebook.react:react-android\")"; added=1}
  ' "$APP_GRADLE"

echo "✅ Patched $APP_GRADLE"
