#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%Y%m%d_%H%M%S)"

# 1) Backup babel.config.js kalau wujud
if [ -f babel.config.js ]; then
  cp babel.config.js "babel.config.js.bak_$TS"
fi

# 2) Install react-native-dotenv
npm install react-native-dotenv@^3.4.8

# 3) Tulis babel.config.js yang serasi dengan Expo + dotenv
cat > babel.config.js <<'EOF'
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      [
        'module:react-native-dotenv',
        {
          moduleName: '@env',
          path: '.env',
          blocklist: null,
          allowlist: null,
          safe: false,
          allowUndefined: true
        }
      ]
    ]
  };
};
EOF

echo "✅ Selesai patch: babel.config.js"
if [ -f "babel.config.js.bak_$TS" ]; then
  echo "🗂️  Backup: babel.config.js.bak_$TS"
fi
echo "➡️  Restart bundler: npx expo start -c"
