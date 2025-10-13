#!/usr/bin/env bash
set -euo pipefail

FILE="android/build.gradle"
test -f "$FILE" || { echo "❌ $FILE tak jumpa. Jalan prebuild dulu."; exit 1; }

cp "$FILE" "${FILE}.bak_$(date +%s)" || true

# Tulis semula build.gradle (root) — AGP & Kotlin SAHAJA, TIADA react-native-gradle-plugin di classpath
cat > "$FILE" <<'GRADLE'
// android/build.gradle (root)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.5.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
        // ❌ JANGAN letak react-native-gradle-plugin di sini (kita includeBuild dari settings.gradle)
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // JitPack hanya jika perlu, dan letak paling bawah:
        // maven { url "https://jitpack.io" }
    }
}
GRADLE

echo "✅ Wrote clean android/build.gradle (AGP+Kotlin only; no RN plugin in classpath)."
