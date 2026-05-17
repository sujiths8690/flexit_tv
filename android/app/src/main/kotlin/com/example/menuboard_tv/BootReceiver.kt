package com.flexit.display

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != Intent.ACTION_SCREEN_ON &&
            action != Intent.ACTION_USER_PRESENT &&
            action != Intent.ACTION_DREAMING_STOPPED
        ) {
            return
        }

        val pendingResult = goAsync()
        Thread {
            try {
                ScheduleStore.refreshFromBackend(context)
                ScheduleStore.applyCurrentSchedule(context)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }
}
