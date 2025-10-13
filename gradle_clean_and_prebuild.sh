#!/usr/bin/env bash
set -euo pipefail
echo "🧹 Cleaning & Prebuild Expo Android..."
cd android
./gradlew clean
cd ..
npx expo prebuild --platform android --clean --non-interactive
cd android
./gradlew assembleRelease --stacktrace
