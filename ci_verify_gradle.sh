#!/usr/bin/env bash
set -euo pipefail

cd android
echo "PWD=$(pwd)"
echo "---- build.gradle (preview) ----"
sed -n '1,120p' build.gradle || true

# Wajib: versi jelas
grep -q 'com.android.tools.build:gradle:8\.5\.2' build.gradle || { echo "AGP versi salah"; exit 1; }
grep -q 'kotlin-gradle-plugin:1\.9\.24' build.gradle || { echo "Kotlin versi salah"; exit 1; }

# Tak boleh: RN plugin dalam classpath
if grep -q 'react-native-gradle-plugin' build.gradle; then
  echo "RN plugin tak boleh dalam classpath"
  exit 1
fi

# settings.gradle quick check
echo "---- settings.gradle checks ----"
grep -q 'mavenCentral()' settings.gradle || { echo "mavenCentral() missing"; exit 1; }
grep -q 'google()' settings.gradle || { echo "google() missing"; exit 1; }

# Brace balance
OPEN=$(grep -o '{' settings.gradle | wc -l | tr -d ' ')
CLOSE=$(grep -o '}' settings.gradle | wc -l | tr -d ' ')
[ "$OPEN" = "$CLOSE" ] || { echo "Brace mismatch settings.gradle {=$OPEN }=$CLOSE"; exit 1; }

echo "✅ VERIFY OK"
