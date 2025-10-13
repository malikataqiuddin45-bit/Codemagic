#!/usr/bin/env bash
set -euo pipefail
APP_GRADLE=android/app/build.gradle
SETTINGS=android/settings.gradle
ROOT=android/build.gradle
MA_FILE=$(echo android/app/src/main/java/*/*/*/MainActivity.kt)
MAP_FILE=$(echo android/app/src/main/java/*/*/*/MainApplication.kt)

# --- app/build.gradle: tambahkan deps jika tiada ---
grep -q 'implementation.*expo-modules-core' "$APP_GRADLE" || \
  awk '1;/dependencies[[:space:]]*{/ && !x{print "    implementation(\"expo.modules:expo-modules-core\")"; x=1}' "$APP_GRADLE" > /tmp/app.gradle && mv /tmp/app.gradle "$APP_GRADLE"

grep -q 'implementation.*com.facebook.react:react-android' "$APP_GRADLE" || \
  awk '1;/dependencies[[:space:]]*{/ && !y{print "    implementation(\"com.facebook.react:react-android\")"; y=1}' "$APP_GRADLE" > /tmp/app.gradle && mv /tmp/app.gradle "$APP_GRADLE"

# --- settings.gradle: pastikan repos ada ---
grep -q 'google()' "$SETTINGS" || sed -i.bak '1s/^/pluginManagement { repositories { google(); mavenCentral() } }\nrepositories { google(); mavenCentral() }\n/' "$SETTINGS"
grep -q 'mavenCentral()' "$SETTINGS" || sed -i.bak '1s/^/pluginManagement { repositories { google(); mavenCentral() } }\nrepositories { google(); mavenCentral() }\n/' "$SETTINGS"

# --- android/build.gradle: AGP & Kotlin plugin (1.9.24), dan buang RN plugin dalam classpath ---
if ! grep -q 'com.android.tools.build:gradle' "$ROOT"; then
  awk '1;/buildscript[[:space:]]*{[[:space:]]*repositories[[:space:]]*{/{f=1} f && /repositories[[:space:]]*{/{print;print "        google()";print "        mavenCentral()";next}1' "$ROOT" > /tmp/root.gradle
  mv /tmp/root.gradle "$ROOT"
  awk '1;/dependencies[[:space:]]*{/{print;print "        classpath(\"com.android.tools.build:gradle:8.5.2\")";next}1' "$ROOT" > /tmp/root.gradle
  mv /tmp/root.gradle "$ROOT"
fi
grep -q 'org.jetbrains.kotlin:kotlin-gradle-plugin:1\.9\.24' "$ROOT" || \
  awk '1;/dependencies[[:space:]]*{/{print;print "        classpath(\"org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24\")";next}1' "$ROOT" > /tmp/root.gradle && mv /tmp/root.gradle "$ROOT"
sed -i.bak '/react-native-gradle-plugin/d' "$ROOT" || true

# --- MainActivity.kt: import wrapper jika missing ---
if ! grep -q 'expo.modules.ReactActivityDelegateWrapper' "$MA_FILE"; then
  sed -i.bak '1i\import expo.modules.ReactActivityDelegateWrapper' "$MA_FILE"
fi

# --- MainApplication.kt: import + wrap host + lifecycle dispatcher ---
if ! grep -q 'expo.modules.ApplicationLifecycleDispatcher' "$MAP_FILE"; then
  sed -i.bak '1i\import expo.modules.ApplicationLifecycleDispatcher' "$MAP_FILE"
fi
if ! grep -q 'expo.modules.ReactNativeHostWrapper' "$MAP_FILE"; then
  sed -i.bak '1i\import expo.modules.ReactNativeHostWrapper' "$MAP_FILE"
fi
# Wrap ReactNativeHost with ReactNativeHostWrapper (only if not already)
if ! grep -q 'ReactNativeHostWrapper' "$MAP_FILE"; then
  sed -i.bak 's/ReactNativeHost(this)/ReactNativeHostWrapper(this, ReactNativeHost(this))/' "$MAP_FILE"
fi
# Ensure lifecycle calls exist
grep -q 'ApplicationLifecycleDispatcher.onCreate(this)' "$MAP_FILE" || \
  sed -i.bak 's/super.onCreate()/super.onCreate()\n        ApplicationLifecycleDispatcher.onCreate(this)/' "$MAP_FILE"
grep -q 'ApplicationLifecycleDispatcher.onConfigurationChanged(this, newConfig)' "$MAP_FILE" || \
  sed -i.bak 's/super.onConfigurationChanged(newConfig)/super.onConfigurationChanged(newConfig)\n        ApplicationLifecycleDispatcher.onConfigurationChanged(this, newConfig)/' "$MAP_FILE"

echo "Patch done."
