#!/usr/bin/env bash
set -e
echo "== Node/Java =="
node -v || true
java -version || true
echo
echo "== Gradle wrapper =="
grep -n 'distributionUrl' android/gradle/wrapper/gradle-wrapper.properties || true
echo
echo "== settings.gradle repos & includeBuild =="
sed -n '1,120p' android/settings.gradle || true
echo
echo "== root build.gradle classpath =="
sed -n '1,120p' android/build.gradle || true
echo
echo "== app/build.gradle (plugins, android block) =="
sed -n '1,200p' android/app/build.gradle || true
echo
echo "== gradle.properties =="
sed -n '1,200p' android/gradle.properties || true
