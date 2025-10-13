#!/usr/bin/env bash
set -euo pipefail

echo "▸ 1) Install & PREBUILD Android (bersih)"
rm -rf android
npm install
npx expo prebuild --platform android --non-interactive --clean

echo "▸ 2) Tulis SEMULA android/settings.gradle (Groovy, tanpa brace lebihan)"
test -d android || { echo "❌ prebuild gagal (tiada folder android)"; exit 1; }
cp android/settings.gradle android/settings.gradle.backup_$(date +%s) 2>/dev/null || true

cat > android/settings.gradle <<'GRADLE'
pluginManagement {
  repositories {
    gradlePluginPortal()
    google()
    mavenCentral()
  }
}

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.name = "app"
include(":app")

def rnGradlePlugin = new File("${rootDir}/../node_modules/react-native-gradle-plugin")
if (rnGradlePlugin.exists()) { includeBuild(rnGradlePlugin) }

def expoAutolinking = new File("${rootDir}/../node_modules/expo-modules-autolinking")
if (expoAutolinking.exists()) { includeBuild(expoAutolinking) }
GRADLE

echo "▸ 3) VERIFY kandungan & kira brace"
echo "----- settings.gradle (with line numbers) -----"
nl -ba android/settings.gradle

echo "----- quick checks -----"
grep -q 'mavenCentral()' android/settings.gradle && echo "  ✓ mavenCentral() OK" || (echo "  ✗ mavenCentral() missing"; exit 1)
grep -q 'google()'       android/settings.gradle && echo "  ✓ google() OK"       || (echo "  ✗ google() missing"; exit 1)

# Kira jumlah '{' dan '}' mesti sama
OPEN=$(grep -o '{' android/settings.gradle | wc -l | tr -d ' ')
CLOSE=$(grep -o '}' android/settings.gradle | wc -l | tr -d ' ')
echo "  • braces: {=$OPEN }=$CLOSE"
[ "$OPEN" = "$CLOSE" ] || { echo "  ✗ jumlah brace tak seimbang"; exit 1; }

echo "▸ 4) Commit & push"
git add android/settings.gradle
git commit -m "fix: rewrite android/settings.gradle (valid Groovy, no extra brace)" || true
git push origin main

echo "✅ Siap. Sekarang run di CodeMagic: Start new build → main → expo54-android"
