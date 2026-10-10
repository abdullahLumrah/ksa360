package com.ksaguide.ksa360

import android.app.Application

class KsaApp : Application() {
    override fun onCreate() {
        super.onCreate()
        PushChannels.ensure(this)
    }
}
