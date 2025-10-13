#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Rewriting codemagic.yaml with safe settings.gradle patch…"

cat > codemagic.yaml <<'YAML'
workflows:
  expo54-android:
    name: Expo 54 Android APK (safe settings.gradle)
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

      - name: Expo prebuild (creates android/)
        script: |
          npx expo prebuild --platform android --non-interactive --clean
          test -f android/settings.gradle || (echo "android/settings.gradle missing after prebuild" && exit 1)

      - name: 🔒 Rewrite android/settings.gradle (Groovy DSL, no extra brace)
        script: |
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

      - name: Verify settings.gradle before build
        script: |
          echo "----- settings.gradle (numbered) -----"
          nl -ba android/settings.gradle
          echo "----- quick checks -----"
          grep -q 'mavenCentral()' android/settings.gradle && echo "✓ mavenCentral()" || (echo "✗ mavenCentral() missing" && exit 1)
          grep -q 'google()' android/settings.gradle && echo "✓ google()" || (echo "✗ google() missing" && exit 1)
          # braces must match
          opens=$(grep -o '{' android/settings.gradle | wc -l | tr -d ' ')
          closes=$(grep -o '}' android/settings.gradle | wc -l | tr -d ' ')
          [ "$opens" = "$closes" ] || (echo "✗ brace mismatch: {=$opens }=$closes" && exit 1)

      - name: Build release APK
        script: |
          cd android
          ./gradlew clean
          ./gradlew assembleRelease -x lint

    artifacts:
      - android/app/build/outputs/**/*.apk
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
YAML

echo "✅ codemagic.yaml rewritten."
git add codemagic.yaml
git commit -m "codemagic: safe rewrite settings.gradle in CI"
git push origin main || echo "⚠️ git push skipped (resolve and push manually)"
