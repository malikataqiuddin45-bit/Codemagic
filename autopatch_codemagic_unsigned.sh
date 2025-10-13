#!/usr/bin/env bash
set -e

echo "🛠️ Patching CodeMagic YAML for unsigned build..."

# Backup dulu
cp codemagic.yaml codemagic.yaml.bak_$(date +%s) || true

# Buang android_signing block kalau ada
sed -i '/android_signing:/,+1d' codemagic.yaml || true

# Pastikan workflow name betul
if ! grep -q "expo54-android:" codemagic.yaml; then
  echo "⚙️ Adding default workflow expo54-android..."
  cat > codemagic.yaml <<'YAML'
workflows:
  expo54-android:
    name: Expo 54 Android APK
    environment:
      node: 20
      java: 17
    scripts:
      - name: Install deps
        script: |
          npm ci || npm install
      - name: Expo prebuild
        script: |
          npx expo prebuild --platform android --non-interactive --clean
      - name: Build release APK
        script: |
          cd android
          ./gradlew clean
          ./gradlew assembleRelease -x lint
    artifacts:
      - android/app/build/outputs/**/*.apk
YAML
fi

echo "✅ codemagic.yaml patched successfully (unsigned build mode)."

echo "🔁 Commit & push changes to GitHub..."
git add codemagic.yaml
git commit -m "autopatch: unsigned codemagic build"
git push origin main || echo "⚠️ Git push skipped (check token or permission)."

echo "✅ Done. Now go to CodeMagic dashboard and click: Start new build → select main → expo54-android."
