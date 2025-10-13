#!/usr/bin/env bash
set -euo pipefail
DIR=android/app/src/main/java/com/redsulphur/forensiknama
mkdir -p "$DIR"
cat > "$DIR/MainActivity.kt" <<'KT'
package com.redsulphur.forensiknama

import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultReactActivityDelegate
import expo.modules.ReactActivityDelegateWrapper

class MainActivity : ReactActivity() {
  override fun createReactActivityDelegate(): ReactActivityDelegate {
    return ReactActivityDelegateWrapper(
      this,
      BuildConfig.IS_NEW_ARCHITECTURE_ENABLED,
      DefaultReactActivityDelegate(this, mainComponentName, false)
    )
  }
}
KT
echo "✅ MainActivity.kt ditulis"
