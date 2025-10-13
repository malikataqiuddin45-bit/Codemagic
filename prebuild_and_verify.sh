#!/usr/bin/env bash
set -euo pipefail

echo "▸ Bersihkan konflik package manager & cache ringkas"
rm -f pnpm-lock.yaml yarn.lock || true
# (optional) npm cache clean --force >/dev/null 2>&1 || true

echo "▸ Install dependencies (npm)"
if [ -f package-lock.json ]; then
  npm ci || npm install
else
  npm install
fi

echo "▸ Reset android/ dan jalankan Expo prebuild"
rm -rf android
npx expo prebuild --platform android --non-interactive --clean

echo "▸ Pastikan android/settings.gradle wujud"
test -f android/settings.gradle || { echo "❌ prebuild tak hasilkan android/settings.gradle"; exit 1; }

echo "▸ Patch minimum settings.gradle (pastikan google() + mavenCentral(), Groovy DSL sah)"
# Backup
cp android/settings.gradle android/settings.gradle.bak_$(date +%s) || true

# Tulis semula versi ringkas & sah (elak brace lebihan)
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

echo "▸ Pastikan expo-modules-core ada dalam app/build.gradle"
grep -q 'implementation("expo.modules:expo-modules-core")' android/app/build.gradle || \
  sed -i '/dependencies\s*{/a\    implementation("expo.modules:expo-modules-core")' android/app/build.gradle

echo "▸ VERIFY (grep):"
echo "  - settings.gradle: mavenCentral() & google()"
grep -q 'mavenCentral()' android/settings.gradle && echo "    ✓ mavenCentral() OK" || echo "    ✗ mavenCentral() MISSING"
grep -q 'google()'       android/settings.gradle && echo "    ✓ google() OK"       || echo "    ✗ google() MISSING"

echo "  - includeBuild (optional, jika ada)"
grep -q 'react-native-gradle-plugin' android/settings.gradle && echo "    ✓ includeBuild RN plugin" || echo "    (info) RN plugin includeBuild tak wajib"
grep -q 'expo-modules-autolinking'   android/settings.gradle && echo "    ✓ includeBuild expo autolinking" || echo "    (info) expo autolinking includeBuild tak wajib"

echo "  - app/build.gradle: expo-modules-core"
grep -q 'expo-modules-core' android/app/build.gradle && echo "    ✓ expo-modules-core OK" || echo "    ✗ expo-modules-core MISSING"

echo "✅ Siap prebuild + verify."
