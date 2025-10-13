#!/usr/bin/env bash
set -euo pipefail
echo "🧩 Step 2: Tambah plugin expo.modules.gradle kalau hilang"

APP_GRADLE="android/app/build.gradle"
if ! grep -q 'id("expo.modules.gradle")' "$APP_GRADLE"; then
  echo "Tambah plugin expo.modules.gradle..."
  sed -i '1 a\id("expo.modules.gradle")' "$APP_GRADLE"
else
  echo "✅ expo.modules.gradle sudah ada"
fi
echo "✅ Step 2 selesai"
