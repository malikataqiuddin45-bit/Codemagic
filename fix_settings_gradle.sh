#!/usr/bin/env bash
set -euo pipefail

mkdir -p android
cat > android/settings.gradle <<'GRADLE'
// Minimal, tanpa sintaks pelik
pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
  resolutionStrategy {
    eachPlugin {
      if (requested.id.id == "org.jetbrains.kotlin.android") {
        useVersion("2.1.20")
      }
    }
  }
  includeBuild("../node_modules/react-native-gradle-plugin")
  includeBuild("../node_modules/expo-modules-autolinking/android/expo-gradle-plugin")
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
  repositories { google(); mavenCentral() }
}
rootProject.name = "app"
include(":app")
GRADLE
echo "✅ settings.gradle ditulis"
