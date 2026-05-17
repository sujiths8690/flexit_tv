package com.flexit.display

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class LaunchAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
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
