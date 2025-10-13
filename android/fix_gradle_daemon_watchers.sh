#!/usr/bin/env bash
set -euo pipefail

echo "🧩 Disable Gradle Daemon + File Watchers untuk Codemagic..."

cat >> android/gradle.properties <<'EOF'

# ==== Codemagic fix: disable file system watchers ====
org.gradle.vfs.watch=false
org.gradle.daemon=false
org.gradle.parallel=false
org.gradle.configureondemand=false
EOF

echo "✅ gradle.properties patched."
cat android/gradle.properties | tail -n 10
