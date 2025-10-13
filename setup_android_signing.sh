#!/usr/bin/env bash
set -euo pipefail

# === Config default (boleh override guna env) ===
KEYSTORE_DIR="${KEYSTORE_DIR:-android/keystores}"
KEYSTORE_FILE="${KEYSTORE_FILE:-$KEYSTORE_DIR/my-release-key.jks}"
KEY_ALIAS="${KEY_ALIAS:-my-key-alias}"
STORE_PASS="${STORE_PASS:-cm123456}"
KEY_PASS="${KEY_PASS:-cm123456}"
DNAME="${DNAME:-CN=Codemagic, OU=Dev, O=App, L=KL, S=MY, C=MY}"
CM_REF="${CM_REF:-my_keystore_ref}"
YAML="${YAML:-codemagic.yaml}"

echo "== Android signing autopatch =="
echo "Keystore will be: $KEYSTORE_FILE"
mkdir -p "$KEYSTORE_DIR"

# === Generate keystore if missing ===
if [ ! -f "$KEYSTORE_FILE" ]; then
  if ! command -v keytool >/dev/null 2>&1; then
    echo "❌ keytool not found. Install JDK or ensure JAVA_HOME is set." >&2
    exit 1
  fi
  echo "Generating keystore..."
  keytool -genkeypair -v \
    -keystore "$KEYSTORE_FILE" \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "$DNAME" >/dev/null
  echo "✅ Keystore generated."
else
  echo "ℹ️ Keystore already exists, skip generate."
fi

# === Save quick info ===
INFO="$KEYSTORE_DIR/keystore_info.txt"
{
  echo "== ANDROID KEYSTORE INFO =="
  echo "File       : $KEYSTORE_FILE"
  echo "Alias      : $KEY_ALIAS"
  echo "Store Pass : $STORE_PASS"
  echo "Key Pass   : $KEY_PASS"
  echo "Ref Name   : $CM_REF"
} > "$INFO"
echo "ℹ️ Info saved -> $INFO"

# === Provide base64 (optional) ===
if command -v base64 >/dev/null 2>&1; then
  B64="$(base64 "$KEYSTORE_FILE" | tr -d '\n')"
  echo "$B64" > "$KEYSTORE_FILE.b64.txt"
  echo "ℹ️ Base64 saved -> $KEYSTORE_FILE.b64.txt (optional)"
fi

# === Patch codemagic.yaml ===
touch "$YAML"

# Insert or replace top-level android_signing block
if grep -qE '^\s*android_signing\s*:' "$YAML"; then
  # replace list with single item CM_REF
  awk -v REF="$CM_REF" '
    BEGIN{inblk=0}
    /^\s*android_signing\s*:/ { print "android_signing:"; print "  - " REF; inblk=1; next }
    { 
      if(inblk){
        if($0 ~ /^[^[:space:]-]/){ inblk=0; print }
        else if($0 ~ /^\s*-/){ next } else { next }
      } else { print }
    }
  ' "$YAML" > "$YAML.tmp" && mv "$YAML.tmp" "$YAML"
else
  printf "\nandroid_signing:\n  - %s\n" "$CM_REF" >> "$YAML"
fi

echo "✅ Patched $YAML to use android_signing: - $CM_REF"

cat <<NOTE

================ NEXT STEPS (Codemagic UI) ================
1) Codemagic dashboard → Settings → Code signing identities → Add new → Android keystore
2) Upload file: $(realpath "$KEYSTORE_FILE")
3) Keystore password : $STORE_PASS
   Key alias         : $KEY_ALIAS
   Key password      : $KEY_PASS
4) Reference name    : $CM_REF
5) Save.

YAML sudah dirujuk ke "$CM_REF".
Sekarang boleh commit & push:

   git add $YAML $KEYSTORE_DIR/keystore_info.txt
   # JANGAN commit .jks ke repo umum jika public.
   # (Biasanya upload terus di Codemagic, tak perlu commit .jks)

============================================================
