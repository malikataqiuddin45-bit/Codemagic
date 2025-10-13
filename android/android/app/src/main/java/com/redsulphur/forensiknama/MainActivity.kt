package com.redsulphur.forensiknama

import com.facebook.react.ReactActivity
import com.facebook.react.ReactActivityDelegate

class MainActivity : ReactActivity() {
  override fun getMainComponentName(): String = "main"
  override fun createReactActivityDelegate() =
    ReactActivityDelegate(this, mainComponentName)
}
