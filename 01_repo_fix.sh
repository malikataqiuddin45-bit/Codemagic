#!/usr/bin/env bash
set -euo pipefail
echo "[Fix] Adjusting Gradle repositories for React Native/Expo"

SETTINGS="android/settings.gradle"
BUILD_ROOT="android/build.gradle"

if [ ! -f "$SETTINGS" ]; then
  echo "No android/ folder yet (run expo prebuild first). Skipping."
  exit 0
fi

# Ensure pluginManagement includes google() and mavenCentral()
if grep -q "pluginManagement" "$SETTINGS"; then
  sed -i '0,/pluginManagement[^{]*{[[:space:]]*repositories[[:space:]]*{/{s//pluginManagement {\n  repositories {\n    gradlePluginPortal()\n    google()\n    mavenCentral()\n  }/}' "$SETTINGS" || true
fi

# Ensure dependencyResolutionManagement with google+mavenCentral
if grep -q "dependencyResolutionManagement" "$SETTINGS"; then
  perl -0777 -pe 's/dependencyResolutionManagement\s*{.*?}/dependencyResolutionManagement {\n  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)\n  repositories {\n    google()\n    mavenCentral()\n  }\n}/s' -i "$SETTINGS" || true
else
  printf '\n\ndependencyResolutionManagement {\n  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)\n  repositories {\n    google()\n    mavenCentral()\n  }\n}\n' >> "$SETTINGS"
fi

# Root build.gradle repos
perl -0777 -pe 's/buildscript\s*{\s*repositories\s*{[^}]*}/buildscript { repositories { google()\n        mavenCentral() } }/s' -i "$BUILD_ROOT" || true
perl -0777 -pe 's/allprojects\s*{\s*repositories\s*{[^}]*}/allprojects { repositories { google()\n        mavenCentral()\n        maven { url "https:\/\/jitpack.io" }\n      } }/s' -i "$BUILD_ROOT" || true

echo "[Fix] Done."
