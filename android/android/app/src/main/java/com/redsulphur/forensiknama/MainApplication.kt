package com.redsulphur.forensiknama

import android.app.Application
import com.facebook.react.PackageList
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint
import com.facebook.react.defaults.DefaultReactNativeHost
import com.facebook.soloader.SoLoader

class MainApplication : Application(), ReactApplication {

  override val reactNativeHost: ReactNativeHost = object : DefaultReactNativeHost(this) {
    override fun getPackages(): List<ReactPackage> = PackageList(this).packages
    override fun getJSMainModuleName() = "index"
    override fun isNewArchEnabled() = DefaultNewArchitectureEntryPoint.getFabricEnabled()
    override fun isHermesEnabled() = BuildConfig.IS_HERMES_ENABLED
  }

  override fun getReactNativeHost() = reactNativeHost

  override fun onCreate() {
    super.onCreate()
    SoLoader.init(this, false)
    if (BuildConfig.IS_NEW_ARCHITECTURE_ENABLED) {
      DefaultNewArchitectureEntryPoint.load()
    }
  }
}
