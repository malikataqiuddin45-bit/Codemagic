package com.redsulphur.forensiknama

import android.os.Build
import android.os.Bundle
import com.facebook.react.ReactActivity
import expo.modules.ReactActivityDelegateWrapper

class MainActivity : ReactActivity() {
    override fun getMainComponentName(): String = "main"

    override fun createReactActivityDelegate() =
        ReactActivityDelegateWrapper(this, ReactActivityDelegate(this, mainComponentName))
}
