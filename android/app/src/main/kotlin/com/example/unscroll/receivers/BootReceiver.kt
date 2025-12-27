package com.unscroll.app.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("UnscrollBoot", "Device booted, accessibility service will auto-start if enabled")
            // The accessibility service will automatically start if it's enabled in settings
            // No manual action needed here
        }
    }
}