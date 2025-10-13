#!/usr/bin/env bash
set -euo pipefail
echo "🧩 Step 4: Bersihkan dan build balik (gradlew clean + assembleRelease)"
cd android
./gradlew clean
./gradlew assembleRelease
echo "✅ Step 4 selesai"
