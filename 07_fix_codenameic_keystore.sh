#!/usr/bin/env bash
set -euo pipefail
echo "🔐 Step 7: Jana keystore untuk Codemagic (local + Base64)"

mkdir -p android/keystore

# 1️⃣ Jana keystore baru (guna password default)
KEY_ALIAS="forensiknama"
KEY_PASS="forensik123"
KEY_PATH="android/keystore/forensiknama.keystore"

if [ ! -f "$KEY_PATH" ]; then
  keytool -genkeypair -v \
    -keystore "$KEY_PATH" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$KEY_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=RedSulphur, OU=Dev, O=RedSulphurOrg, L=BatuPahat, S=Johor, C=MY"
  echo "✅ Keystore dijana di $KEY_PATH"
else
  echo "✅ Keystore sedia ada digunakan"
fi

# 2️⃣ Convert ke Base64 untuk upload ke Codemagic ENV
echo "➡️  Encode Base64 untuk Codemagic ENV..."
base64 "$KEY_PATH" > android/keystore/forensiknama.keystore.base64
echo "✅ Simpan di android/keystore/forensiknama.keystore.base64"

# 3️⃣ Paparkan environment variable template
echo ""
echo "⚙️  === TAMBAH DALAM CODEMAGIC ENVIRONMENT ==="
echo "CM_KEYSTORE=<salin kandungan file Base64 ni>"
echo "CM_KEYSTORE_PATH=forensiknama.keystore"
echo "CM_KEYSTORE_PASSWORD=$KEY_PASS"
echo "CM_KEY_ALIAS=$KEY_ALIAS"
echo "CM_KEY_PASSWORD=$KEY_PASS"
echo "=============================================="
