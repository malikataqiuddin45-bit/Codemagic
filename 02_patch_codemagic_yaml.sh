#!/usr/bin/env bash
set -euo pipefail

YML=codemagic.yaml
cat > "$YML" <<'YAML'
workflows:
  expo54_android_apk:
    name: Expo 54 Android APK (with Kotlin debug)
    max_build_duration: 60
    environment:
      vars:
        EXPO_NO_TELEMETRY: "1"
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
    scripts:
      - name: Install deps
        script: |
          npm ci || npm install --legacy-peer-deps

      - name: Expo prebuild (Android)
        script: |
          npx expo prebuild --platform android --non-interactive --clean

      - name: Show deps (releaseCompileClasspath)
        script: |
          cd android
          ./gradlew :app:dependencies --configuration releaseCompileClasspath \
            | grep -i "expo-modules-core" || true
          cd ..

      - name: Debug Kotlin compile (print exact errors)
        script: |
          set -e
          cd android
          # cuba compile Kotlin sahaja supaya log tunjuk baris 'e: ...'
          if ! ./gradlew :app:compileReleaseKotlin --no-daemon --stacktrace --info | tee /tmp/kotlin_release.log; then
            echo "---------- Kotlin error lines ----------"
            grep -n '^e: ' /tmp/kotlin_release.log || true
            echo "----------------------------------------"
            exit 1
          fi
          cd ..

      - name: Build APK
        script: |
          cd android
          ./gradlew --no-daemon assembleRelease -x lint --stacktrace

    artifacts:
      - android/app/build/outputs/**/*.apk
YAML

echo "✅ Wrote $YML (workflow: expo54_android_apk)"
