package com.redsulphur.forensiknama

import com.facebook.react.ReactActivity
import expo.modules.ReactActivityDelegateWrapper
import com.facebook.react.ReactActivityDelegate

class MainActivity : ReactActivity() {
  override fun getMainComponentName(): String = "main"
  override fun createReactActivityDelegate() =
    ReactActivityDelegateWrapper(this, ReactActivityDelegate(this, mainComponentName))
}
