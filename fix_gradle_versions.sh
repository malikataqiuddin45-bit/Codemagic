#!/usr/bin/env bash
set -e

echo "🔧 Baiki android/build.gradle"
cat > android/build.gradle <<'GRADLE'
// Root-level build file
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
        // ❌ Jangan tambah react-native-gradle-plugin di sini
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
GRADLE

echo "✅ android/build.gradle dikemaskini dengan AGP 8.5.2 & Kotlin 1.9.24"
echo "🔎 Semak ringkas:"
grep -E 'gradle|kotlin' android/build.gradle
