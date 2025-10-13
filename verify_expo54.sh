#!/usr/bin/env bash
set -e

echo "== VERIFY Expo 54 Android =="
test -f android/settings.gradle || { echo "❌ android/settings.gradle tiada (prebuild gagal)"; exit 1; }
test -f android/app/build.gradle || { echo "❌ android/app/build.gradle tiada (prebuild gagal)"; exit 1; }

echo "• Repositories (settings.gradle):"
grep -q 'mavenCentral()' android/settings.gradle && echo "  ✓ mavenCentral()" || { echo "  ✗ mavenCentral() MISSING"; exit 1; }
grep -q 'google()'       android/settings.gradle && echo "  ✓ google()"       || { echo "  ✗ google() MISSING"; exit 1; }

echo "• includeBuild (settings.gradle):"
grep -q 'react-native-gradle-plugin'      android/settings.gradle && echo "  ✓ react-native-gradle-plugin"      || echo "  ⚠ tak jumpa (tak wajib di setiap template)"
grep -q 'expo-modules-autolinking'        android/settings.gradle && echo "  ✓ expo-modules-autolinking"        || echo "  ⚠ tak jumpa (prebuild tertentu inline-kan autolinking)"

echo "• Dependencies (app/build.gradle):"
grep -q 'implementation("expo.modules:expo-modules-core")' android/app/build.gradle && echo "  ✓ expo-modules-core" || { echo "  ✗ expo-modules-core MISSING"; exit 1; }

echo "== OK: Struktur Expo 54 lengkap. =="
