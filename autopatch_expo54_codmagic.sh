#!/usr/bin/env bash
set -e
echo "🚀 Autopatching Codemagic + Gradle for Expo SDK 54 (RN 0.81)..."

# Pastikan Gradle wrapper betul
cat > android/gradle/wrapper/gradle-wrapper.properties <<'GRADLE'
distributionUrl=https\://services.gradle.org/distributions/gradle-8.6-bin.zip
GRADLE

# Betulkan settings.gradle
cat > android/settings.gradle <<'SETTINGS'
pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}
rootProject.name = "app"
include(":app")
SETTINGS

# Betulkan build.gradle root
cat > android/build.gradle <<'BUILD'
buildscript {
  repositories {
    google()
    mavenCentral()
  }
  dependencies {
    classpath("com.android.tools.build:gradle:8.5.2")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
  }
}
allprojects {
  repositories {
    google()
    mavenCentral()
  }
}
BUILD

# Betulkan codemagic.yaml
cat > codemagic.yaml <<'YAML'
workflows:
  expo54:
    name: "Expo SDK 54 Android APK"
    max_build_duration: 60
    environment:
      vars:
        NODE_VERSION: 20
        JAVA_VERSION: 17
        EXPO_NO_TELEMETRY: "1"
    scripts:
      - name: Install deps
        script: |
          rm -f yarn.lock package-lock.json pnpm-lock.yaml
          npm install
      - name: Expo prebuild (Android)
        script: |
          npx expo prebuild --platform android --non-interactive --clean
      - name: Build APK
        script: |
          cd android
          ./gradlew clean
          ./gradlew assembleRelease --stacktrace
    artifacts:
      - android/app/build/outputs/**/*.apk
YAML

echo "✅ Codemagic + Gradle config diselaraskan. Push ke repo dan build di Codemagic."
