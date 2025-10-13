#!/usr/bin/env bash
set -euo pipefail

PKG=$(sed -n 's/.*package="\([^"]*\)".*/\1/p' android/app/src/main/AndroidManifest.xml | head -n1)
DIR="android/app/src/main/java/$(echo "$PKG" | tr . /)"
MA="$DIR/MainActivity.kt"
MP="$DIR/MainApplication.kt"

echo "📄 Semak dan tambah method getMainComponentName() dalam MainActivity..."
if ! grep -q 'getMainComponentName' "$MA"; then
  sed -i.bak '/class MainActivity : ReactActivity()/a\
    override fun getMainComponentName(): String = "main"
  ' "$MA"
  echo "✅ Ditambah getMainComponentName()"
else
  echo "✅ Dah ada getMainComponentName()"
fi

echo "📄 Semak dan tambah PackageList(this).packages dalam MainApplication..."
if ! grep -q 'PackageList(this).packages' "$MP"; then
  sed -i.bak '/override fun getPackages()/,/}/c\
    override fun getPackages(): List<ReactPackage> {\
        return PackageList(this).packages\
    }' "$MP"
  echo "✅ Ditambah PackageList(this).packages"
else
  echo "✅ Dah ada PackageList(this).packages"
fi

echo "🔎 Verify ringkas:"
grep -n 'getMainComponentName' "$MA" || true
grep -n 'PackageList(this).packages' "$MP" || true

echo "✅ Final Kotlin fix siap."
