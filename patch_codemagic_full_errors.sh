#!/usr/bin/env bash
set -euo pipefail

cat > codemagic.yaml <<'YAML'
workflows:
  expo54_android_apk:
    name: Expo 54 Android APK (FULL ERRORS)
    max_build_duration: 60
    environment:
      vars:
        EXPO_NO_TELEMETRY: "1"
        GRADLE_OPTS: "-Dorg.gradle.logging.level=info"
    cache:
      cache_paths:
        - $CM_BUILD_DIR/node_modules
        - $CM_BUILD_DIR/android/.gradle
        - $HOME/.gradle/caches

    scripts:
      - name: Install deps
        script: |
          set -euxo pipefail
          npm ci || npm install --legacy-peer-deps

      - name: Expo prebuild (Android)
        script: |
          set -euxo pipefail
          npx expo prebuild --platform android --non-interactive --clean

      - name: Show deps (releaseCompileClasspath)
        script: |
          set -euxo pipefail
          cd android
          ./gradlew :app:dependencies --configuration releaseCompileClasspath \
            --no-daemon --console=plain | tee /tmp/deps_release.log >/dev/null
          grep -i "expo-modules-core" /tmp/deps_release.log || true
          cd ..

      - name: Debug Kotlin compile (print exact errors + context)
        script: |
          set -e
          cd android
          # Log penuh ke fail
          ./gradlew :app:compileReleaseKotlin \
            --no-daemon --stacktrace --info --warning-mode all --console=plain \
            -Dkotlin.daemon.verbose=true \
            -Dkotlin.compiler.execution.strategy=in-process \
            2>&1 | tee /tmp/kotlin_release_full.log
          STATUS=${PIPESTATUS[0]}
          # Tunjuk SEMUA baris error + 40 baris konteks
          echo "---------- Kotlin error blocks (with context) ----------"
          awk '
            BEGIN{printing=0; ctx=40}
            /^e: /{printing=1; count=0}
            printing{print; count++}
            printing && count>=ctx{printing=0}
          ' /tmp/kotlin_release_full.log || true
          echo "--------------------------------------------------------"
          # Kalau fail compile, hentikan di sini (biar kita nampak error penuh)
          if [ "$STATUS" -ne 0 ]; then
            echo "❌ Kotlin compile failed (see full log in artifacts)."
            # Cetak keseluruhan log supaya UI Codemagic tak truncate
            echo "========== FULL kotlin_release_full.log =========="
            cat /tmp/kotlin_release_full.log
            echo "=================================================="
            exit 1
          fi
          cd ..

      - name: Build APK (debug log saved)
        script: |
          set -e
          cd android
          ./gradlew assembleRelease -x lint --no-daemon --stacktrace --debug \
            2>&1 | tee /tmp/gradle_assemble_debug.log || { \
              echo "========== FULL gradle_assemble_debug.log =========="; \
              cat /tmp/gradle_assemble_debug.log; \
              echo "===================================================="; \
              exit 1; }
          cd ..

    artifacts:
      - /tmp/*.log
      - android/app/build/outputs/**/*.apk
YAML

echo "✅ codemagic.yaml updated (FULL ERRORS)."
echo "�� Commit & push:"
echo "   git add codemagic.yaml && git commit -m 'ci: print full kotlin/gradle errors' && git push"
