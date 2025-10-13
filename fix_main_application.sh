#!/usr/bin/env bash
set -euo pipefail
DIR=android/app/src/main/java/com/redsulphur/forensiknama
mkdir -p "$DIR"
cat > "$DIR/MainApplication.kt" <<'KT'
package com.redsulphur.forensiknama

import android.app.Application
import android.content.res.Configuration
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.react.defaults.DefaultReactNativeHost
import expo.modules.ApplicationLifecycleDispatcher
import expo.modules.ReactNativeHostWrapper

class MainApplication : Application(), ReactApplication {
  override val reactNativeHost: ReactNativeHost by lazy {
    ReactNativeHostWrapper(this,
      object : DefaultReactNativeHost(this) {
        override fun getUseDeveloperSupport() = BuildConfig.DEBUG
        override fun getPackages() = packageList
      }
    )
  }

  override fun onCreate() {
    super.onCreate()
    ApplicationLifecycleDispatcher.onApplicationCreate(this)
  }

  override fun onConfigurationChanged(newConfig: Configuration) {
    super.onConfigurationChanged(newConfig)
    ApplicationLifecycleDispatcher.onConfigurationChanged(this, newConfig)
  }
}
KT
echo "✅ MainApplication.kt ditulis"
