#!/usr/bin/env bash
set -euo pipefail
red(){ printf "\033[31m✗ %s\033[0m\n" "$*"; }
grn(){ printf "\033[32m✓ %s\033[0m\n" "$*"; }

APP_GRADLE=android/app/build.gradle
SETTINGS=android/settings.gradle
ROOT=android/build.gradle
MA=android/app/src/main/java/*/*/*/MainActivity.kt
MAP=android/app/src/main/java/*/*/*/MainApplication.kt

echo "== Files =="
echo "settings : $SETTINGS"
echo "root     : $ROOT"
echo "app      : $APP_GRADLE"

FAIL=0

# deps
if grep -q 'implementation.*expo-modules-core' "$APP_GRADLE"; then grn "expo-modules-core ada (OK)"; else red "expo-modules-core MISSING dalam app/build.gradle"; FAIL=1; fi
if grep -q 'implementation.*com.facebook.react:react-android' "$APP_GRADLE"; then grn "react-android ada (OK)"; else red "react-android MISSING dalam app/build.gradle"; FAIL=1; fi

# repos
if grep -q 'google()' "$SETTINGS" && grep -q 'mavenCentral()' "$SETTINGS"; then grn "google() & mavenCentral() ada dalam settings (OK)"; else red "Repo google()/mavenCentral() MISSING dalam settings.gradle"; FAIL=1; fi

# classpath / plugin
if grep -q 'com.android.tools.build:gradle' "$ROOT"; then grn "AGP classpath ada (OK)"; else red "AGP classpath MISSING dalam android/build.gradle"; FAIL=1; fi
if grep -q 'org.jetbrains.kotlin:kotlin-gradle-plugin:1\.9\.24' "$ROOT" || grep -q 'id[[:space:]]*"org.jetbrains.kotlin.android"[[:space:]]*version[[:space:]]*"1\.9\.24"' "$ROOT"; then
  grn "Kotlin gradle plugin 1.9.24 ada (OK)"
else
  red "Kotlin gradle plugin 1.9.24 MISSING dalam android/build.gradle"; FAIL=1
fi
if grep -q 'react-native-gradle-plugin' "$ROOT"; then red "JANGAN letak react-native-gradle-plugin dalam buildscript classpath (REMOVE)"; FAIL=1; else grn "Tiada RN gradle plugin dalam classpath (OK)"; fi

# expo imports
egrep -q 'import[[:space:]]+expo\.modules\.ReactActivityDelegateWrapper' $MA 2>/dev/null && grn "Import ReactActivityDelegateWrapper ada (OK)" || { red "Import ReactActivityDelegateWrapper MISSING (MainActivity.kt)"; FAIL=1; }
egrep -q 'import[[:space:]]+expo\.modules\.ApplicationLifecycleDispatcher' $MAP 2>/dev/null && grn "Import ApplicationLifecycleDispatcher ada (OK)" || { red "Import ApplicationLifecycleDispatcher MISSING (MainApplication.kt)"; FAIL=1; }
egrep -q 'import[[:space:]]+expo\.modules\.ReactNativeHostWrapper' $MAP 2>/dev/null && grn "Import ReactNativeHostWrapper ada (OK)" || { red "Import ReactNativeHostWrapper MISSING (MainApplication.kt)"; FAIL=1; }

echo "-----------------------------"
if [ "$FAIL" -eq 0 ]; then echo "All checks PASSED"; exit 0; else echo "Ada yang MISSING / mismatch"; exit 1; fi
