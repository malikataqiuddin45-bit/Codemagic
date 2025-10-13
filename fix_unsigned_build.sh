#!/usr/bin/env bash
set -euo pipefail

YAML="codemagic.yaml"

# pastikan file wujud
touch "$YAML"

# padam baris android_signing kalau ada
sed -i.bak '/android_signing:/,/^$/d' "$YAML" || true

# tambah block untuk unsigned build
cat <<'YML' >> "$YAML"

workflows:
  react_native_unsigned:
    name: "React Native Android (Unsigned)"
    max_build_duration: 60
    instance_type: mac_mini_m1
    environment:
      vars:
        NODE_VERSION: 18.18.2
      node: 18.18.2
    scripts:
      - name: Install dependencies
        script: |
          npm install
      - name: Expo prebuild
        script: |
          npx expo prebuild --platform android
      - name: Build APK unsigned
        script: |
          cd android
          ./gradlew assembleRelease
    artifacts:
      - android/app/build/outputs/**/*.apk
YML

echo "✅ Patched codemagic.yaml for unsigned build (react_native_unsigned)."
echo "➡️  Sekarang boleh push dan pilih workflow 'React Native Android (Unsigned)' dalam Codemagic."
