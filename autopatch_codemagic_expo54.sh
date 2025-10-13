#!/usr/bin/env bash
set -e
echo "🚀 Autopatching Codemagic YAML for Expo SDK 54 Android build..."

# Buat fail codemagic.yaml di root
cat > codemagic.yaml <<'YAML'
workflows:
  expo54-android:
    name: Expo 54 Android APK
    environment:
      node: 20
      java: 17
      vars:
        CI: "true"
        EXPO_NO_TELEMETRY: "1"

    scripts:
      - name: Install dependencies
        script: |
          rm -f yarn.lock pnpm-lock.yaml
          npm ci || npm install

      - name: Expo prebuild (Android)
        script: |
          npx expo prebuild --platform android --non-interactive --clean
          test -f android/settings.gradle || (echo "android/settings.gradle missing" && exit 1)

      - name: Enforce Gradle wrapper 8.6
        script: |
          cd android
          ./gradlew wrapper --gradle-version 8.6 --distribution-type bin
          ./gradlew --version

      - name: Normalize settings.gradle
        script: |
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

      - name: Normalize root build.gradle
        script: |
          cat > android/build.gradle <<'GRADLE'
          // Root-level build file
          buildscript {
            repositories { google(); mavenCentral() }
            dependencies {
              classpath("com.android.tools.build:gradle:8.5.2")
              classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
            }
          }
          allprojects { repositories { google(); mavenCentral() } }
          GRADLE

      - name: Build release APK
        script: |
          cd android
          ./gradlew clean
          ./gradlew assembleRelease -x lint --stacktrace

    artifacts:
      - android/app/build/outputs/**/*.apk
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
YAML

echo "✅ codemagic.yaml created successfully"
git add codemagic.yaml
git commit -m "add: Codemagic template for Expo 54 Android build"
echo "✅ Commit ready. Push ke repo dan run di Codemagic."
