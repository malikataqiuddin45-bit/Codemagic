#!/usr/bin/env bash
set -e
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
      - name: Use npm only
        script: |
          rm -f pnpm-lock.yaml yarn.lock
      - name: Install deps
        script: |
          npm ci || npm install
      - name: Expo prebuild (creates android/)
        script: |
          npx expo prebuild --platform android --non-interactive --clean
      - name: Sanity checks
        script: |
          test -f android/settings.gradle || (echo "settings.gradle missing after prebuild" && exit 1)
          grep -q "mavenCentral()" android/settings.gradle || (echo "Missing mavenCentral() in settings.gradle" && exit 1)
          grep -q "google()"       android/settings.gradle || (echo "Missing google() in settings.gradle" && exit 1)
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
echo "✔ codemagic.yaml ditulis di root."
