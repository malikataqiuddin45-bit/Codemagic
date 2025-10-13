#!/usr/bin/env bash
set -euo pipefail
APP=android/app/build.gradle

# pastikan blok dependencies wujud
grep -q '^[[:space:]]*dependencies[[:space:]]*{' "$APP" || printf '\n\ndependencies {\n}\n' >> "$APP"

# expo-modules-core (idempotent)
grep -q 'expo.modules:expo-modules-core' "$APP" || \
  gawk -i inplace '
    BEGIN{done=0}
    {print}
    /^[[:space:]]*dependencies[[:space:]]*{/ && !done {print "    implementation(\"expo.modules:expo-modules-core\")"; done=1}
  ' "$APP"

# react-android (idempotent)
grep -q 'com.facebook.react:react-android' "$APP" || \
  gawk -i inplace '
    BEGIN{done=0}
    {print}
    /^[[:space:]]*dependencies[[:space:]]*{/ && !done {print "    implementation(\"com.facebook.react:react-android\")"; done=1}
  ' "$APP"

echo "✅ Patched $APP (expo-modules-core + react-android)"
