#!/usr/bin/env bash
set -euo pipefail

echo "🩹 Membaiki android/settings.gradle ..."

SETG="android/settings.gradle"

# pastikan folder android wujud
if [ ! -f "$SETG" ]; then
  echo "📦 Tiada android/settings.gradle, buat baru..."
  mkdir -p android
fi

# backup
cp "$SETG" "${SETG}.bak_$(date +%s)" 2>/dev/null || true

# tulis semula fail dengan kod Groovy sah
cat > "$SETG" <<'GRADLE'
pluginManagement {
  repositories {
    gradlePluginPortal()
    google()
    mavenCentral()
  }
}

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.name = "app"
include(":app")

// optional untuk react-native & expo autolinking
def rnGradlePlugin = new File("${rootDir}/../node_modules/react-native-gradle-plugin")
if (rnGradlePlugin.exists()) { includeBuild(rnGradlePlugin) }

def expoAutolinking = new File("${rootDir}/../node_modules/expo-modules-autolinking")
if (expoAutolinking.exists()) { includeBuild(expoAutolinking) }
GRADLE

echo "✅ settings.gradle dibaiki dan disimpan semula."
echo "💾 Backup: ${SETG}.bak_*"

# commit & push
git add "$SETG"
git commit -m "fix: rewrite android/settings.gradle (valid Groovy DSL)"
git push origin main || echo "⚠️ Push gagal (mungkin token/permission). Check semula access."
