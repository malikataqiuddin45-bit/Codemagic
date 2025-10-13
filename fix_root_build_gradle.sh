#!/usr/bin/env bash
set -euo pipefail
mkdir -p android
cat > android/build.gradle <<'GRADLE'
buildscript {
  repositories { google(); mavenCentral() }
  dependencies {
    classpath("com.android.tools.build:gradle:8.5.2")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20")
  }
}
allprojects { repositories { google(); mavenCentral() } }
GRADLE
echo "✅ root build.gradle ditulis"
