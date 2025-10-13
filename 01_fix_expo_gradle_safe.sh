#!/usr/bin/env bash
set -euo pipefail
echo "🧩 Step 1: Pastikan expo-modules-core wujud dalam dependencies"

APP_GRADLE="android/app/build.gradle"
if [ ! -f "$APP_GRADLE" ]; then
  echo "❌ File tak jumpa: $APP_GRADLE"
  exit 1
fi

if ! grep -q 'expo.modules:expo-modules-core' "$APP_GRADLE"; then
  echo "Tambah expo.modules:expo-modules-core..."
  awk '
    /dependencies *\{/ && !added {
      print "    implementation(\"expo.modules:expo-modules-core\")"
      added=1
    }
    {print}
  ' "$APP_GRADLE" > tmp && mv tmp "$APP_GRADLE"
else
  echo "✅ expo-modules-core sudah ada"
fi
echo "✅ Step 1 selesai"
