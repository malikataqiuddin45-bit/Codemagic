#!/usr/bin/env bash
set -euo pipefail
echo "🧩 Step 6: Patch settings.gradle & build.gradle untuk aktifkan Expo autolinking"

# 1️⃣ Fail wajib
SETTINGS="android/settings.gradle"
APP_GRADLE="android/app/build.gradle"

if [ ! -f "$SETTINGS" ]; then
  echo "❌ File tak jumpa: $SETTINGS"
  echo "➡️  Jalankan dulu: npx expo prebuild --platform android"
  exit 1
fi

# 2️⃣ Patch settings.gradle kalau hilang plugin
if ! grep -q 'expo-modules-autolinking' "$SETTINGS"; then
  echo "➡️  Tambah expo-modules-autolinking plugin ke settings.gradle..."
  cat > "$SETTINGS" <<'EOF'
pluginManagement {
    includeBuild("../node_modules/@react-native/gradle-plugin")
    includeBuild("../node_modules/expo-modules-autolinking/android/expo-gradle-plugin")
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

plugins {
    id("com.facebook.react.settings") version "+" apply false
    id("expo.modules.settings") apply false
}

apply(plugin = "com.facebook.react.settings")
apply(plugin = "expo.modules.settings")

rootProject.name = "forensiknama"
include(":app")
EOF
else
  echo "✅ settings.gradle sudah lengkap"
fi

# 3️⃣ Pastikan app/build.gradle ada plugin expo.modules.gradle
if [ -f "$APP_GRADLE" ]; then
  if ! grep -q 'expo.modules.gradle' "$APP_GRADLE"; then
    echo "➡️  Tambah plugin expo.modules.gradle ke app/build.gradle..."
    sed -i '1 a\id("expo.modules.gradle")' "$APP_GRADLE"
  else
    echo "✅ expo.modules.gradle sudah ada"
  fi
else
  echo "⚠️  File build.gradle belum wujud — abaikan dulu"
fi

echo "✅ Step 6 siap — autolinking Expo aktif"
