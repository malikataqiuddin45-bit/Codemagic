#!/usr/bin/env bash
set -euo pipefail
echo "== Cek import expo dalam .kt =="
grep -R --include='*.kt' -nE \
  'ReactActivityDelegateWrapper|ReactNativeHostWrapper|ApplicationLifecycleDispatcher' \
  android/app/src/main/java || true

echo "== Cek expo-modules-core dalam dependencies =="
./android/gradlew -p android :app:dependencies \
  --configuration releaseCompileClasspath | grep -i "expo-modules-core" || true

echo "== Cek repos di settings.gradle =="
grep -nE 'pluginManagement|repositories|gradlePluginPortal|RepositoriesMode' android/settings.gradle
