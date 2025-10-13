#!/usr/bin/env bash
set -e
test -f android/settings.gradle || { echo "❌ Tiada android/settings.gradle (jalan prebuild dulu)"; exit 1; }
test -f android/app/build.gradle || { echo "❌ Tiada android/app/build.gradle (jalan prebuild dulu)"; exit 1; }

echo "▸ VERIFY settings.gradle"
grep -q 'mavenCentral()' android/settings.gradle && echo "  ✓ mavenCentral()" || echo "  ✗ mavenCentral() MISSING"
grep -q 'google()'       android/settings.gradle && echo "  ✓ google()"       || echo "  ✗ google() MISSING"

echo "▸ VERIFY expo-modules-core"
grep -q 'implementation("expo.modules:expo-modules-core")' android/app/build.gradle \
  && echo "  ✓ expo-modules-core" || echo "  ✗ expo-modules-core MISSING"
