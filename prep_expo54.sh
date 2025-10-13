#!/usr/bin/env bash
set -e

echo "▸ Guna npm sahaja (buang lockfile lain)…"
rm -f pnpm-lock.yaml yarn.lock || true

echo "▸ Install deps…"
if [ -f package-lock.json ]; then
  npm ci || npm install
else
  npm install
fi

echo "▸ Reset android/ & prebuild Expo 54…"
rm -rf android
npx expo prebuild --platform android --non-interactive --clean

echo "✔ Siap prebuild (android/ wujud)."
