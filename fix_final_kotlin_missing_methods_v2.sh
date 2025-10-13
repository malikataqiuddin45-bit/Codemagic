#!/usr/bin/env bash
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
PKG=$(sed -n 's/.*package="\([^"]*\)".*/\1/p' "$MANIFEST" | head -n1)
DIR="android/app/src/main/java/$(echo "$PKG" | tr . /)"
MA="$DIR/MainActivity.kt"
MP="$DIR/MainApplication.kt"

if [ ! -f "$MA" ]; then
  echo "❌ Tak jumpa $MA — semak path package!"
  echo "📁 Cuba cari manual: android/app/src/main/java/"
  find android/app/src/main/java -name "MainActivity.kt" || true
  exit 1
fi

echo "📄 Patch MainActivity..."
if ! grep -q 'getMainComponentName' "$MA"; then
  sed -i.bak '/class MainActivity/a\
    override fun getMainComponentName(): String = "main"
  ' "$MA"
  echo "✅ Tambah getMainComponentName()"
else
  echo "✅ Dah ada getMainComponentName()"
fi

echo "📄 Patch MainApplication..."
if ! grep -q 'PackageList(this).packages' "$MP"; then
  sed -i.bak '/override fun getPackages()/,/}/c\
    override fun getPackages(): List<ReactPackage> {\
        return PackageList(this).packages\
    }' "$MP"
  echo "✅ Tambah PackageList(this).packages"
else
  echo "✅ Dah ada PackageList(this).packages"
fi

echo "🔍 Verify ringkas:"
grep -n 'getMainComponentName' "$MA" || true
grep -n 'PackageList(this).packages' "$MP" || true
echo "✅ Fix siap (auto detect path package: $PKG)"
