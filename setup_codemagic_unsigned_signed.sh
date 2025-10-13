#!/usr/bin/env bash
set -euo pipefail

# --- Guard ---
if [ ! -f package.json ]; then
  echo "❌ Jalankan skrip di root repo (mesti ada package.json)."
  exit 1
fi

# --- Backup codemagic.yaml jika wujud ---
if [ -f codemagic.yaml ]; then
  cp codemagic.yaml codemagic.yaml.bak.$(date +%Y%m%d-%H%M%S)
  echo "🗂  Backup codemagic.yaml -> codemagic.yaml.bak.*"
fi

# --- Tulis codemagic.yaml dengan dua workflow: unsigned & signed ---
cat > codemagic.yaml <<'YAML'
workflows:
  expo54_apk_unsigned:
    name: Expo 54 • APK (Unsigned)
    max_build_duration: 60
    environment:
      vars:
        NODE_VERSION: "20"
        EXPO_NO_TELEMETRY: "1"
      flutter: stable
      xcode: latest
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
    scripts:
      - name: Use Node
        script: |
          set -euxo pipefail
          . $HOME/.nvm/nvm.sh
          nvm install $NODE_VERSION
          nvm use $NODE_VERSION
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
          tail -n +1 android/gradle/gradle.properties

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
      # Guna keystore yang anda upload di Codemagic UI → "Code signing identities"
      # Tukar 'my_keystore_ref' ikut "Reference name" anda
      android_signing:
        - my_keystore_ref
      vars:
        NODE_VERSION: "20"
        EXPO_NO_TELEMETRY: "1"
      flutter: stable
      xcode: latest
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches
    scripts:
      - name: Use Node
        script: |
          set -euxo pipefail
          . $HOME/.nvm/nvm.sh
          nvm install $NODE_VERSION
          nvm use $NODE_VERSION
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
          tail -n +1 android/gradle/gradle.properties

      - name: Build APK (signed)
        script: |
          set -euxo pipefail
          cd android
          ./gradlew assembleRelease --no-daemon --stacktrace --console=plain
          # Nota: Codemagic export env CM_KEYSTORE_* secara automatik bila 'android_signing' di atas diset.

    artifacts:
      - android/app/build/outputs/**/*.apk
      - android/app/build/outputs/**/mapping.txt
YAML

echo "✅ Tulis codemagic.yaml (unsigned + signed)."

# --- Tunjuk ringkas apa yang ditulis ---
echo "----- codemagic.yaml (head) -----"
sed -n '1,120p' codemagic.yaml
echo "---------------------------------"

echo
echo "👉 Seterusnya, commit & push:"
echo "   git add codemagic.yaml"
echo "   git commit -m 'ci: add Codemagic workflows (Expo 54 unsigned & signed)'"
echo "   git push"
echo
echo "🔐 Untuk workflow 'Signed':"
echo "   - Di Codemagic UI → Code signing identities → Upload Android keystore"
echo "   - Set Reference name (cth: my_keystore_ref) dan pastikan sama dgn YAML"
echo "   - Codemagic akan set CM_KEYSTORE_PATH/ALIAS/PASSWORD secara automatik"
