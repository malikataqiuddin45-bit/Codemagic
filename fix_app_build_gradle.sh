#!/usr/bin/env bash
set -euo pipefail
mkdir -p android/app
cat > android/app/build.gradle <<'GRADLE'
plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace "com.redsulphur.forensiknama"
  compileSdk 36
  defaultConfig {
    applicationId "com.redsulphur.forensiknama"
    minSdk 24
    targetSdk 36
    versionCode 1
    versionName "1.0"
  }
  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
  kotlinOptions { jvmTarget = "17" }
}

dependencies {
  implementation("expo.modules:expo-modules-core")
  implementation("com.facebook.react:react-android")
}
GRADLE
echo "✅ app/build.gradle ditulis"
