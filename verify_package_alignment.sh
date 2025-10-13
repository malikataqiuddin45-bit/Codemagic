#!/usr/bin/env bash
set -euo pipefail

# Baca package dari AndroidManifest
MANIFEST="android/app/src/main/AndroidManifest.xml"
PKG=$(sed -n 's/.*package="\([^"]*\)".*/\1/p' "$MANIFEST" | head -n1)
echo "📦 Manifest package: $PKG"

# Cek namespace & applicationId dalam app/build.gradle
echo "🔎 app/build.gradle:"
grep -nE '^\s*namespace\s+"|^\s*applicationId\s+"' android/app/build.gradle || true

# Cek path fail Kotlin ikut package
DIR="android/app/src/main/java/$(echo "$PKG" | tr . /)"
echo "📁 Kotlin dir sepatutnya: $DIR"
ls -la "$DIR" || { echo "❌ Folder Kotlin ikut package tak jumpa"; exit 1; }

# Cek import Expo/RN wajib
echo "🔎 Import wajib (expo & RN wrappers):"
grep -R -nE 'ReactActivityDelegateWrapper|ReactNativeHostWrapper|ApplicationLifecycleDispatcher' "$DIR" || { echo "❌ Import expo.* tak lengkap"; exit 1; }

# Cek mainComponentName & PackageList
echo "🔎 getMainComponentName & PackageList:"
grep -R -n 'getMainComponentName' "$DIR" || echo "⚠️ getMainComponentName tiada"
grep -R -n 'PackageList(this).packages' "$DIR" || echo "⚠️ PackageList(this).packages tiada"

echo "✅ VERIFY OK (struktur nampak betul jika tiada ❌ di atas)."
