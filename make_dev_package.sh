#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-ForensikNama}"
TS="$(date +%Y%m%d_%H%M%S)"

DEV_ZIP="${APP_NAME}_dev_pkg_${TS}.zip"
FULL_ZIP="${APP_NAME}_full_with_node_modules_${TS}.zip"

echo "==> Menjana .env.example (tanpa rahsia)…"
if [ -f .env ]; then
  # Buat salinan contoh tanpa nilai sensitif (ganti dengan PLACEHOLDER)
  awk '{
    if ($0 ~ /^[A-Za-z0-9_]+=/) {
      split($0,a,"="); print a[1]"="((a[1] ~ /KEY|TOKEN|SECRET|PASSWORD/)? "REPLACE_ME":"REPLACE_ME")
    } else { print $0 }
  }' .env > .env.example
else
  cat > .env.example <<EOF
# Contoh .env — isikan nilai sebenar pada mesin build
EXPO_PUBLIC_APP_NAME=Forensik Nama
EXPO_PUBLIC_APP_VERSION=1.0.0
EXPO_PUBLIC_SCHEME=forensiknama
# EXPO_PUBLIC_SUPABASE_URL=
# EXPO_PUBLIC_SUPABASE_ANON_KEY=
EOF
fi

echo "==> Memeriksa fail penting…"
for f in package.json app.json babel.config.js; do
  [ -f "$f" ] || { echo "❌ Tiada $f"; exit 1; }
done
[ -f package-lock.json ] || [ -f pnpm-lock.yaml ] || [ -f yarn.lock ] || {
  echo "⚠️  Tiada lockfile. Disaran jalankan: npm i --package-lock-only"; }

echo "==> Membina ZIP untuk DEVELOPER (tanpa node_modules)…"
zip -rq "$DEV_ZIP" . \
  -x "node_modules/*" \
     ".git/*" \
     ".github/*" \
     "android/*" \
     "ios/*" \
     "*.log" \
     "*.tgz" \
     "*.zip" \
     ".DS_Store" \
     ".*.swp"

echo "==> (Opsyen) Membina FULL BACKUP termasuk node_modules…"
zip -rq "$FULL_ZIP" . \
  -x ".git/*" ".github/*" "*.log" ".DS_Store" ".*.swp"

echo
echo "✅ Siap."
echo "   • Developer package : $DEV_ZIP"
echo "   • Full backup       : $FULL_ZIP"
echo
echo "Nota untuk developer:"
echo "1) npm ci   # atau npm install"
echo "2) npx expo prebuild && npx expo run:android   # debug build"
echo "   atau"
echo "   eas build -p android --profile production   # production AAB/APK"
