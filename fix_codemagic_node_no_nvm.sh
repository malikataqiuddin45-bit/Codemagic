#!/usr/bin/env bash
set -euo pipefail

# Guard
[ -f package.json ] || { echo "❌ Jalankan di root repo (mesti ada package.json)"; exit 1; }

# Backup kalau ada
[ -f codemagic.yaml ] && cp codemagic.yaml codemagic.yaml.bak.$(date +%Y%m%d-%H%M%S)

# Tulis semula codemagic.yaml: TANPA nvm, pin Node/npm
cat > codemagic.yaml <<'YAML'
workflows:
  expo54_apk_unsigned:
    name: Expo 54 • APK (Unsigned)
    max_build_duration: 60
    environment:
      # Pin tools preinstalled oleh Codemagic (tanpa NVM)
      node: 20
      npm: 10
      vars:
        EXPO_NO_TELEMETRY: "1"
      flutter: stable
      xcode: latest
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
    scripts:
      - name: Show Node/npm
        script: |
          set -euxo pipefail
          node -v
          npm -v

      - name: Install deps
        script: |
          set -euxo pipefail
          npm ci || npm install --legacy-peer-deps

      - name: Expo prebuild (Android)
        script: |
          set -euxo pipefail
          npx expo prebuild --platform android --non-interactive --clean

      - name: CI-friendly Gradle settings
        script: |
          set -euxo pipefail
          mkdir -p android/gradle
          cat > android/gradle/gradle.properties <<'EOF'
          org.gradle.console=plain
          org.gradle.daemon=false
          org.gradle.parallel=false
          org.gradle.vfs.watch=false
          org.gradle.workers.max=1
          kotlin.compiler.execution.strategy=in-process
          kotlin.incremental=false
          EOF

      - name: Build APK (unsigned)
        script: |
          set -euxo pipefail
          cd android
          ./gradlew assembleRelease --no-daemon --stacktrace --console=plain

    artifacts:
      - android/app/build/outputs/**/*.apk
      - android/app/build/outputs/**/mapping.txt

  expo54_apk_signed:
    name: Expo 54 • APK (Signed)
    max_build_duration: 60
    environment:
      # Upload keystore kat Codemagic UI → Code signing identities
      # Tukar "my_keystore_ref" ikut Reference name yang kau set
      android_signing:
        - my_keystore_ref
      node: 20
      npm: 10
      vars:
        EXPO_NO_TELEMETRY: "1"
      flutter: stable
      xcode: latest
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
    scripts:
      - name: Show Node/npm
        script: |
          set -euxo pipefail
          node -v
          npm -v

      - name: Install deps
        script: |
          set -euxo pipefail
          npm ci || npm install --legacy-peer-deps

      - name: Expo prebuild (Android)
        script: |
          set -euxo pipefail
          npx expo prebuild --platform android --non-interactive --clean

      - name: CI-friendly Gradle settings
        script: |
          set -euxo pipefail
          mkdir -p android/gradle
          cat > android/gradle/gradle.properties <<'EOF'
          org.gradle.console=plain
          org.gradle.daemon=false
          org.gradle.parallel=false
          org.gradle.vfs.watch=false
          org.gradle.workers.max=1
          kotlin.compiler.execution.strategy=in-process
          kotlin.incremental=false
          EOF

      - name: Build APK (signed)
        script: |
          set -euxo pipefail
          cd android
          ./gradlew assembleRelease --no-daemon --stacktrace --console=plain
          # CM_KEYSTORE_* akan auto-available bila android_signing di atas wujud

    artifacts:
      - android/app/build/outputs/**/*.apk
      - android/app/build/outputs/**/mapping.txt
YAML

echo "✅ Siap tulis codemagic.yaml tanpa NVM & pin Node/npm."
echo "�� Seterusnya:"
echo "   git add codemagic.yaml"
echo "   git commit -m 'ci: pin Node/npm & remove NVM on Codemagic'"
echo "   git push"
echo
echo "🔐 Untuk workflow Signed: upload keystore & set 'my_keystore_ref' dalam Codemagic UI."
