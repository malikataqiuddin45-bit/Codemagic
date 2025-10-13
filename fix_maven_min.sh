#!/usr/bin/env bash
set -e
SETTINGS="android/settings.gradle"

test -f "$SETTINGS" || { echo "❌ $SETTINGS tak jumpa. Jalankan prebuild dulu."; exit 1; }

# pluginManagement (tambah kalau tiada)
grep -q "pluginManagement" "$SETTINGS" || \
  sed -i '1ipluginManagement {\n  repositories {\n    gradlePluginPortal()\n    google()\n    mavenCentral()\n  }\n}\n' "$SETTINGS"

# dependencyResolutionManagement (replace/isi minima)
if grep -q "dependencyResolutionManagement" "$SETTINGS"; then
  # ganti keseluruhan blok dengan versi minima yang betul
  awk '
    BEGIN{skip=0}
    /dependencyResolutionManagement[[:space:]]*{/ {print "dependencyResolutionManagement {";
      print "  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)";
      print "  repositories {";
      print "    google()";
      print "    mavenCentral()";
      print "  }";
      print "}";
      skip=1; next}
    skip==1 && /}/ { skip=0; next }
    skip==0 { print }
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
else
  cat <<'EOF' >> "$SETTINGS"

dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}
EOF
fi

echo "✔ settings.gradle OK (google() + mavenCentral())."
