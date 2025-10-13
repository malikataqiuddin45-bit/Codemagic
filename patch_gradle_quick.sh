#!/usr/bin/env bash
set -e
APP=android/app/build.gradle
echo "→ Patched $APP"

if ! grep -q 'expo-modules-core' "$APP"; then
  sed -i '/dependencies\s*{/a\    implementation("expo.modules:expo-modules-core")' "$APP"
  echo "✅ add expo-modules-core"
fi

if ! grep -q 'react-android' "$APP"; then
  sed -i '/dependencies\s*{/a\    implementation("com.facebook.react:react-android")' "$APP"
  echo "✅ add react-android"
fi
