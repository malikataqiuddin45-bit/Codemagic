#!/usr/bin/env bash
set -euo pipefail

echo "▸ Pin Gradle wrapper → 8.6 (serasi AGP 8.5.2)"
mkdir -p android/gradle/wrapper
if [ -f android/gradle/wrapper/gradle-wrapper.properties ]; then
  cp android/gradle/wrapper/gradle-wrapper.properties android/gradle/wrapper/gradle-wrapper.properties.bak_$(date +%s)
fi
cat > android/gradle/wrapper/gradle-wrapper.properties <<'PROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.6-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROPS

echo "▸ Root build.gradle: set AGP & Kotlin versi jelas, tiada RN plugin dalam classpath"
cat > android/build.gradle <<'GRADLE'
// android/build.gradle (root)
buildscript {
  repositories { google(); mavenCentral() }
  dependencies {
    classpath("com.android.tools.build:gradle:8.5.2")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    // Jangan tambah react-native-gradle-plugin di sini
  }
}
allprojects { repositories { google(); mavenCentral() } }
GRADLE

echo "▸ settings.gradle kekal Groovy & repos OK"
cat > android/settings.gradle <<'GRADLE'
pluginManagement { repositories { gradlePluginPortal(); google(); mavenCentral() } }
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
  repositories { google(); mavenCentral() }
}
rootProject.name = "app"
include(":app")
def rnGradlePlugin = new File("${rootDir}/../node_modules/react-native-gradle-plugin")
if (rnGradlePlugin.exists()) { includeBuild(rnGradlePlugin) }
def expoAutolinking = new File("${rootDir}/../node_modules/expo-modules-autolinking")
if (expoAutolinking.exists()) { includeBuild(expoAutolinking) }
GRADLE

echo "▸ Tambah guard dalam gradle.properties"
grep -q '^org.gradle.jvmargs' android/gradle.properties 2>/dev/null || echo 'org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8' >> android/gradle.properties

echo "▸ Update codemagic.yaml supaya CI guna wrapper 8.6 & log penuh"
cat > codemagic.yaml <<'YAML'
workflows:
  expo54-android:
    name: Expo 54 Android APK (pinned Gradle 8.6)
    environment:
      node: 20
      java: 17
      vars:
        CI: "true"
        EXPO_NO_TELEMETRY: "1"
    scripts:
      - name: Install deps
        script: |
          rm -f pnpm-lock.yaml yarn.lock
          npm ci || npm install

      - name: Expo prebuild
        script: |
          npx expo prebuild --platform android --non-interactive --clean

      - name: Enforce Gradle wrapper 8.6
        script: |
          cd android
          ./gradlew --version || true
          ./gradlew wrapper --gradle-version 8.6 --distribution-type bin
          cat gradle/wrapper/gradle-wrapper.properties | sed -n '1,200p'

      - name: Verify classpath versions
        script: |
          grep -q 'com.android.tools.build:gradle:8.5.2' android/build.gradle || (echo "AGP versi salah" && exit 1)
          grep -q 'kotlin-gradle-plugin:1.9.24' android/build.gradle || (echo "Kotlin versi salah" && exit 1)
          if grep -q 'react-native-gradle-plugin' android/build.gradle; then echo "RN plugin tak boleh dalam classpath"; exit 1; fi

      - name: Build release APK
        script: |
          cd android
          ./gradlew clean
          ./gradlew assembleRelease -x lint --stacktrace --warning-mode=all

    artifacts:
      - android/app/build/outputs/**/*.apk
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
YAML

echo "▸ Commit & push"
git add android/gradle/wrapper/gradle-wrapper.properties android/build.gradle android/settings.gradle android/gradle.properties codemagic.yaml
git commit -m "pin: Gradle 8.6 + AGP 8.5.2 + Kotlin 1.9.24; enforce in CI with full logs"
git push origin main || echo "⚠️ Push gagal. Run: git pull --rebase && git push"
echo "✅ Siap. Start build di CodeMagic (workflow: Expo 54 Android APK (pinned Gradle 8.6))."
