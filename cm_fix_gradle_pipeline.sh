#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Overwrite codemagic.yaml dengan langkah prebuild → rewrite gradle files → verify → build"

cat > codemagic.yaml <<'YAML'
workflows:
  expo54-android:
    name: Expo 54 Android APK (fixed gradle)
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

      - name: Rewrite settings.gradle (Groovy, no stray brace)
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

      - name: Rewrite root android/build.gradle (AGP + Kotlin ONLY)
        script: |
          cat > android/build.gradle <<'GRADLE'
// android/build.gradle (root)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // explicit versions (NO empty ':')
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
        // DO NOT put RN gradle plugin here; it's included via settings.gradle includeBuild()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
          GRADLE

      - name: Verify gradle files
        script: |
          echo "---- android/build.gradle ----"
          grep -nE 'classpath|repositories' android/build.gradle || true
          grep -Eq 'com\.android\.tools\.build:gradle:([0-9]+\.)+[0-9]+' android/build.gradle || (echo "AGP version missing/empty" && exit 1)
          grep -Eq 'org\.jetbrains\.kotlin:kotlin-gradle-plugin:([0-9]+\.)+[0-9]+' android/build.gradle || (echo "Kotlin plugin version missing/empty" && exit 1)
          if grep -Eq 'react-native-gradle-plugin' android/build.gradle; then echo "RN plugin must NOT be in classpath" && exit 1; fi
          echo "---- android/settings.gradle ----"
          grep -q 'mavenCentral()' android/settings.gradle || (echo "mavenCentral() missing" && exit 1)
          grep -q 'google()' android/settings.gradle || (echo "google() missing" && exit 1)
          opens=$(grep -o '{' android/settings.gradle | wc -l | tr -d ' ')
          closes=$(grep -o '}' android/settings.gradle | wc -l | tr -d ' ')
          [ "$opens" = "$closes" ] || (echo "Brace mismatch in settings.gradle" && exit 1)
          echo "VERIFY OK"

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

git add codemagic.yaml
git commit -m "codemagic: rewrite settings.gradle + build.gradle after prebuild (fix classpath versions)"
git push origin main || echo "⚠️ Push gagal, run: git pull --rebase && git push"
echo "✅ Done. Pergi CodeMagic → Start new build (branch main, workflow 'fixed gradle')."
