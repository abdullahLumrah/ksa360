package com.ksaguide.ksa360

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

object PushChannels {
    const val ID = "ksa360_default"

    fun ensure(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            ID,
            "KSA 360",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "News and alerts from KSA 360"
        channel.enableVibration(true)
        channel.enableLights(true)
        channel.setShowBadge(true)
        manager.createNotificationChannel(channel)
    }
}
