#!/usr/bin/env bash
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"

# --- Tentukan DIR ---
DIR=""
if [ -f "$MANIFEST" ]; then
  PKG=$(sed -n 's/.*package="\([^"]*\)".*/\1/p' "$MANIFEST" | head -n1 || true)
  if [ -n "${PKG:-}" ]; then
    DIR="android/app/src/main/java/$(echo "$PKG" | tr . /)"
  fi
fi

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "⚠️  Gagal detect package dari Manifest, fallback cari MainActivity.kt ..."
  FOUND=$(find android/app/src/main/java -name "MainActivity.kt" -print -quit || true)
  if [ -n "$FOUND" ]; then
    DIR=$(dirname "$FOUND")
  fi
fi

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "❌ Tak jumpa direktori package. Senarai calon:"
  find android/app/src/main/java -maxdepth 6 -type f -name "MainActivity.kt" || true
  exit 1
fi

MA="$DIR/MainActivity.kt"
MP="$DIR/MainApplication.kt"

if [ ! -f "$MA" ]; then
  echo "❌ Tak jumpa $MA"
  find android/app/src/main/java -name "MainActivity.kt" || true
  exit 1
fi
if [ ! -f "$MP" ]; then
  echo "❌ Tak jumpa $MP"
  find android/app/src/main/java -name "MainApplication.kt" || true
  exit 1
fi

# Helper sed cross-platform (macOS/BSD vs GNU)
sedi() {
  if sed --version >/dev/null 2>&1; then
    sed -i.bak "$@"
  else
    sed -i '' "$@"
  fi
}

echo "📄 Patch MainActivity.kt ($MA)"
if ! grep -q 'getMainComponentName' "$MA"; then
  sedi '/class MainActivity/a\
    override fun getMainComponentName(): String = "main"
  ' "$MA"
  echo "✅ Tambah getMainComponentName()"
else
  echo "✅ Dah ada getMainComponentName()"
fi

echo "📄 Patch MainApplication.kt ($MP)"
if ! grep -q 'PackageList(this).packages' "$MP"; then
  # ganti keseluruhan body getPackages() kepada PackageList(this).packages
  awk '
    BEGIN{found=0}
    /override[[:space:]]+fun[[:space:]]+getPackages\(\)/{found=1; print "    override fun getPackages(): List<ReactPackage> {"; print "        return PackageList(this).packages"; print "    }"; skip=1; next}
    skip && /\}/ {skip=0; next}
    !skip {print}
  ' "$MP" > "$MP.tmp" && mv "$MP.tmp" "$MP"
  echo "✅ Set getPackages() → PackageList(this).packages"
else
  echo "✅ Dah ada PackageList(this).packages"
fi

echo "🔍 Verify ringkas:"
grep -n 'getMainComponentName' "$MA" || true
grep -n 'PackageList(this).packages' "$MP" || true
echo "🎯 Siap. DIR: $DIR"
