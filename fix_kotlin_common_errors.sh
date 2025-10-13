#!/usr/bin/env bash
set -euo pipefail

# Cari package dir dari AndroidManifest
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  PKG=$(sed -n 's/.*package="\([^"]*\)".*/\1/p' "$MANIFEST" | head -n1)
else
  echo "❌ Tak jumpa $MANIFEST"; exit 1
fi
DIR="android/app/src/main/java/$(echo "$PKG" | tr . /)"
MA="$DIR/MainActivity.kt"
MP="$DIR/MainApplication.kt"

[ -f "$MA" ] || { echo "❌ $MA tak wujud"; exit 1; }
[ -f "$MP" ] || { echo "❌ $MP tak wujud"; exit 1; }

echo "📄 Patch $MA"
# 1) Pastikan ada getMainComponentName() = "main"
grep -q 'getMainComponentName' "$MA" || \
  sed -i.bak '1h;1!H;$!d;${g;s/class MainActivity : ReactActivity() {/class MainActivity : ReactActivity() {\n  override fun getMainComponentName(): String = "main"/}' "$MA"

# 2) Pastikan panggilan DefaultReactActivityDelegate gunakan getMainComponentName()
#    Tukar ...DefaultReactActivityDelegate(this, mainComponentName, false) -> getMainComponentName()
sed -i.bak 's/DefaultReactActivityDelegate(this, *mainComponentName, *false)/DefaultReactActivityDelegate(this, getMainComponentName(), false)/' "$MA"

# 3) Import yang perlu (idempotent)
add_import() {
  local FILE="$1" LINE="$2"
  grep -qF "$LINE" "$FILE" || sed -i.bak "1{/^package /!b};1a $LINE" "$FILE"
}
add_import "$MA" "import com.facebook.react.ReactActivity"
add_import "$MA" "import com.facebook.react.ReactActivityDelegate"
add_import "$MA" "import com.facebook.react.defaults.DefaultReactActivityDelegate"
add_import "$MA" "import expo.modules.ReactActivityDelegateWrapper"
add_import "$MA" "import expo.modules.ApplicationLifecycleDispatcher"
add_import "$MA" "import android.content.res.Configuration"
add_import "$MA" "import android.os.Bundle"

echo "📄 Patch $MP"
# 4) Gantikan getPackages() supaya guna PackageList(this).packages
if grep -q 'getPackages()' "$MP"; then
  # Import PackageList jika belum
  add_import "$MP" "import com.facebook.react.PackageList"
  # Tukar body getPackages (apa jua isi) kepada PackageList(this).packages
  awk '
    BEGIN{inMethod=0}
    /getPackages\(\)/{
      inMethod=1
      print
      next
    }
    inMethod==1 && /{/{
      print
      print "        return PackageList(this).packages"
      next
    }
    inMethod==1 && /}/{
      print
      inMethod=0
      next
    }
    {print}
  ' "$MP" > "$MP.tmp" && mv "$MP.tmp" "$MP"
fi

# 5) Pastikan import Expo wrappers wujud
add_import "$MP" "import expo.modules.ReactNativeHostWrapper"
add_import "$MP" "import expo.modules.ApplicationLifecycleDispatcher"
add_import "$MP" "import android.content.res.Configuration"

echo "✅ Selesai patch."
echo "🔎 Ringkas verify:"
echo " - getMainComponentName():"
grep -n 'getMainComponentName' "$MA" || true
echo " - DefaultReactActivityDelegate(... getMainComponentName() ..."
grep -n 'DefaultReactActivityDelegate(.*getMainComponentName' "$MA" || true
echo " - getPackages() body:"
grep -n 'PackageList(this).packages' "$MP" || true
