#!/usr/bin/env bash
set -e
test -f android/settings.gradle || { echo "❌ Tiada android/. Jalan prebuild dulu."; exit 1; }
cd android
./gradlew clean
./gradlew assembleRelease
