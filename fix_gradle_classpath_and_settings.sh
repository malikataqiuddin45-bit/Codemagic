#!/usr/bin/env bash
set -euo pipefail

echo "▸ 0) Guna npm sahaja (buang lock lain)"
rm -f pnpm-lock.yaml yarn.lock || true

echo "▸ 1) Install deps & PREBUILD android/"
[ -f package-lock.json ] && npm ci || npm install
rm -rf android
npx expo prebuild --platform android --non-interactive --clean

test -f android/settings.gradle || { echo "❌ prebuild gagal (tiada android/settings.gradle)"; exit 1; }

echo "▸ 2) Tulis SEMULA android/settings.gradle (Groovy DSL valid, tiada brace lebihan)"
cp android/settings.gradle android/settings.gradle.bak_$(date +%s) 2>/dev/null || true
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

// Optional includeBuild (guna kalau wujud)
def rnGradlePlugin = new File("${rootDir}/../node_modules/react-native-gradle-plugin")
if (rnGradlePlugin.exists()) { includeBuild(rnGradlePlugin) }

def expoAutolinking = new File("${rootDir}/../node_modules/expo-modules-autolinking")
if (expoAutolinking.exists()) { includeBuild(expoAutolinking) }
GRADLE

echo "▸ 3) Tulis SEMULA android/build.gradle (AGP + Kotlin SAHAJA, TIADA RN plugin classpath)"
FILE="android/build.gradle"
test -f "$FILE" || touch "$FILE"
cp "$FILE" "${FILE}.bak_$(date +%s)" 2>/dev/null || true
cat > "$FILE" <<'GRADLE'
// android/build.gradle (root)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Versi EXPLICIT; JANGAN kosong
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
        // ❌ JANGAN letak react-native-gradle-plugin di sini. Ia diurus melalui includeBuild() dalam settings.gradle
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // maven { url "https://jitpack.io" } // hanya jika benar-benar perlu
    }
}
GRADLE

echo "▸ 4) Sanity checks"
echo "   – Pastikan TIADA classpath versi kosong:"
! grep -E 'classpath\("com\.android\.tools\.build:gradle:?\."\)' -n android/build.gradle || { echo "✗ AGP kosong"; exit 1; }
! grep -E 'classpath\("org\.jetbrains\.kotlin:kotlin-gradle-plugin:?\."\)' -n android/build.gradle || { echo "✗ Kotlin plugin kosong"; exit 1; }
! grep -E 'react-native-gradle-plugin:?\."' -n android/build.gradle || echo "   ✓ Tiada RN plugin dalam classpath (bagus)"
echo "   – settings.gradle repos:"
grep -q 'mavenCentral()' android/settings.gradle && echo "   ✓ mavenCentral()" || { echo "✗ mavenCentral() missing"; exit 1; }
grep -q 'google()'       android/settings.gradle && echo "   ✓ google()"       || { echo "✗ google() missing"; exit 1; }

echo "▸ 5) Commit & push"
git add android/settings.gradle android/build.gradle
git commit -m "fix: Gradle classpath versions + valid settings.gradle (Expo54/RN0.81)"
git push origin main || { echo "⚠️ git push gagal (perlu pull/rebase dulu)"; exit 0; }

echo "✅ Selesai. Di CodeMagic, run build semula (assembleRelease)."
