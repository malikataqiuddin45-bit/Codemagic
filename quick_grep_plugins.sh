#!/usr/bin/env bash
set -euo pipefail

red()  { printf "❌ %s\n" "$*"; }
green(){ printf "✅ %s\n" "$*"; }
warn(){ printf "🟨 %s\n" "$*"; }

FAIL=0

A_SETTINGS="android/settings.gradle"
A_SETTINGS_KTS="android/settings.gradle.kts"
A_ROOT_GRADLE="android/build.gradle"
A_APP_GRADLE="android/app/build.gradle"
A_APP_GRADLE_KTS="android/app/build.gradle.kts"

# pick files that exist
file_first() {
  for f in "$@"; do [ -f "$f" ] && { echo "$f"; return; }; done
  echo ""
}

SETTINGS_FILE=$(file_first "$A_SETTINGS" "$A_SETTINGS_KTS")
ROOT_FILE=$(file_first "$A_ROOT_GRADLE")
APP_FILE=$(file_first "$A_APP_GRADLE" "$A_APP_GRADLE_KTS")

echo "== Files =="
echo "settings  : ${SETTINGS_FILE:-<missing>}"
echo "root gradle: ${ROOT_FILE:-<missing>}"
echo "app  gradle: ${APP_FILE:-<missing>}"
echo

# --- Check repos (google+mavenCentral) in settings / root ---
if [ -n "$SETTINGS_FILE" ]; then
  if grep -Eq 'google\(\)' "$SETTINGS_FILE" && grep -Eq 'mavenCentral\(\)' "$SETTINGS_FILE"; then
    green "Repos OK dalam settings.gradle"
  else
    red   "Repos MISSING dalam settings.gradle (google() / mavenCentral())"
    FAIL=1
  fi
elif [ -n "$ROOT_FILE" ]; then
  if grep -Eq 'google\(\)' "$ROOT_FILE" && grep -Eq 'mavenCentral\(\)' "$ROOT_FILE"; then
    green "Repos OK dalam android/build.gradle"
  else
    red   "Repos MISSING dalam android/build.gradle (google() / mavenCentral())"
    FAIL=1
  fi
else
  red "settings.gradle & android/build.gradle kedua-dua MISSING"
  FAIL=1
fi

# --- Check plugin com.android.application in app module ---
if [ -n "$APP_FILE" ]; then
  if grep -Eq "id ['\"]com\.android\.application['\"]|apply plugin: ['\"]com\.android\.application['\"]" "$APP_FILE"; then
    green "Plugin AGP (com.android.application) OK dalam app/build.gradle"
  else
    red   "Plugin AGP MISSING dalam app/build.gradle"
    FAIL=1
  fi
else
  red "app/build.gradle MISSING"
  FAIL=1
fi

# --- Check Kotlin Android plugin in app module ---
if [ -n "$APP_FILE" ]; then
  if grep -Eq "id ['\"]org\.jetbrains\.kotlin\.android['\"]|apply plugin: ['\"]kotlin-android['\"]" "$APP_FILE"; then
    green "Plugin Kotlin Android OK dalam app/build.gradle"
  else
    red   "Plugin Kotlin Android MISSING dalam app/build.gradle"
    FAIL=1
  fi
fi

# --- Ensure RN Gradle plugin NOT in root classpath (yang lama) ---
if [ -n "$ROOT_FILE" ]; then
  if grep -Eq 'classpath\(.+react-native-gradle-plugin' "$ROOT_FILE"; then
    red "JANGAN letak react-native-gradle-plugin dalam buildscript classpath (android/build.gradle)"
    FAIL=1
  else
    green "Tiada react-native-gradle-plugin dalam classpath (OK)"
  fi
fi

# --- Check expo-modules-core dependency in app (untuk Expo 54) ---
if [ -n "$APP_FILE" ]; then
  if grep -Eq "implementation\(['\"]expo\.modules:expo-modules-core" "$APP_FILE"; then
    green "Dependency expo-modules-core ada (OK)"
  else
    warn  "expo-modules-core MISSING dalam app/build.gradle (Expo biasanya tambah auto, tapi baik pastikan)"
  fi
fi

# --- Ringkasan ---
echo
if [ "$FAIL" -eq 0 ]; then
  echo "=========================="
  echo " All plugin checks PASSED "
  echo "=========================="
  exit 0
else
  echo "=========================="
  echo " Ada plugin yang MISSING! "
  echo "=========================="
  exit 1
fi
