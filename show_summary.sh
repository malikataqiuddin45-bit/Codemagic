#!/usr/bin/env bash
set -euo pipefail
echo "---- SUMMARY ----"
echo "Files:"
find android/app/src/main/java/com/redsulphur/forensiknama -maxdepth 1 -name '*.kt' -print
echo
echo "Imports (expo):"
grep -R --include='*.kt' -E 'expo.modules|ReactActivityDelegateWrapper|ReactNativeHostWrapper|ApplicationLifecycleDispatcher' \
  android/app/src/main/java | sed 's/^/ - /'
echo
echo "Gradle:"
head -n 40 android/settings.gradle | sed 's/^/ [settings] /'
head -n 40 android/build.gradle | sed 's/^/ [root] /'
head -n 80 android/app/build.gradle | sed 's/^/ [app] /'
echo "------------------"
