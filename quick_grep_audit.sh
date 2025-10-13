#!/usr/bin/env bash
set -e

echo "🔍 Audit ringkas fail Gradle (Expo 54 / RN 0.81)"

check_file() {
  if [ ! -f "$1" ]; then
    echo "❌ $1 TIADA"
    return 1
  fi
}

check_brace_balance() {
  local FILE="$1"
  local OPEN=$(grep -o '{' "$FILE" | wc -l | tr -d ' ')
  local CLOSE=$(grep -o '}' "$FILE" | wc -l | tr -d ' ')
  echo "  ⚙️  $FILE → {=$OPEN }=$CLOSE"
  if [ "$OPEN" != "$CLOSE" ]; then
    echo "  ❌ Brace tak seimbang → mungkin ada } lebihan"
    return 1
  else
    echo "  ✅ Brace seimbang"
  fi
}

echo "🧾 1️⃣ android/settings.gradle"
check_file android/settings.gradle || exit 1
grep -nE 'repositories|dependencyResolutionManagement|pluginManagement' android/settings.gradle || true
check_brace_balance android/settings.gradle

echo ""
echo "🧾 2️⃣ android/build.gradle (root)"
check_file android/build.gradle || exit 1
grep -nE 'classpath|repositories' android/build.gradle || true
grep -n 'react-native-gradle-plugin' android/build.gradle && echo "❌ react-native-gradle-plugin JANGAN ada dalam classpath!" || echo "✅ Tiada react-native-gradle-plugin dalam classpath"
grep -Eq 'gradle:[0-9]' android/build.gradle && echo "✅ Ada versi AGP" || echo "❌ Tiada versi AGP"
grep -Eq 'kotlin-gradle-plugin:[0-9]' android/build.gradle && echo "✅ Ada versi Kotlin" || echo "❌ Tiada versi Kotlin"

echo ""
echo "🧾 3️⃣ android/app/build.gradle"
check_file android/app/build.gradle || exit 1
grep -n 'expo-modules-core' android/app/build.gradle && echo "✅ expo-modules-core OK" || echo "⚠️ expo-modules-core belum ada"

echo ""
echo "📊 RINGKASAN"
grep -q 'mavenCentral()' android/settings.gradle && echo "✅ mavenCentral() OK" || echo "❌ mavenCentral() missing"
grep -q 'google()' android/settings.gradle && echo "✅ google() OK" || echo "❌ google() missing"

echo ""
echo "🎯 Audit siap. Jika SEMUA tanda ✅ → build dah selamat run kat CodeMagic."
