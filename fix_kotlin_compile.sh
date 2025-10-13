#!/usr/bin/env bash
set -e

# A) app/build.gradle → Java 17 + jvmTarget 17
awk '1;/android *\{/{p=1} /compileOptions *\{/{p=0} END{}' android/app/build.gradle >/dev/null 2>&1 || true
grep -q 'compileOptions' android/app/build.gradle || cat >> android/app/build.gradle <<'G'
android {
  compileSdkVersion 34
  defaultConfig {
    minSdkVersion 23
    targetSdkVersion 34
  }
  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
}
G

grep -q 'kotlinOptions' android/app/build.gradle || cat >> android/app/build.gradle <<'K'
kotlinOptions { jvmTarget = "17" }
K

# B) Root build.gradle → force stdlib & coroutines
if ! grep -q 'resolutionStrategy' android/build.gradle; then
cat >> android/build.gradle <<'RS'

subprojects {
  configurations.all {
    resolutionStrategy {
      force "org.jetbrains.kotlin:kotlin-stdlib:1.9.24"
      force "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.24"
      force "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1"
      force "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.1"
    }
  }
}
RS
fi

# C) Wrapper 8.6
mkdir -p android/gradle/wrapper
printf "distributionUrl=https\\://services.gradle.org/distributions/gradle-8.6-bin.zip\n" > android/gradle/wrapper/gradle-wrapper.properties

echo "✅ Patch siap."
