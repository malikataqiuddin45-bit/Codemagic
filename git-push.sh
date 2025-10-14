#!/usr/bin/env bash
set -euo pipefail
MSG="${1:-chore: push from codespace}"
BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
git add -A
git commit -m "$MSG" || echo "No changes to commit."
if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push -u origin "$BR"
else
  git pull --rebase
  git push
fi
echo "✅ Pushed to origin/$BR"
