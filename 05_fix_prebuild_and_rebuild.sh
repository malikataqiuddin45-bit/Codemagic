#!/usr/bin/env bash
set -euo pipefail
echo "🧩 Step 5: Jalankan prebuild Expo untuk buat folder android + build semula"

# 1️⃣ Buat folder android kalau belum ada
if [ ! -d "android" ]; then
  echo "➡️  Tiada folder android — jalankan prebuild..."
  npx expo prebuild --platform android --clean
else
  echo "✅ Folder android dah ada"
fi

# 2️⃣ Semak semula build.gradle
if [ ! -f "android/app/build.gradle" ]; then
  echo "⚠️  build.gradle belum dijumpai — mungkin prebuild gagal."
  echo "Cuba manual: npx expo prebuild --platform android --clean"
  exit 1
fi

# 3️⃣ Build semula
cd android
echo "➡️  Bersihkan & build release..."
./gradlew clean
./gradlew assembleRelease

echo "✅ Step 5 siap — APK akan muncul di android/app/build/outputs/apk/release/"
