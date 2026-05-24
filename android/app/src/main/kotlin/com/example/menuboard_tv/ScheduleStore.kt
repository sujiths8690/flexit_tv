package com.flexit.display

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import java.util.Calendar

object ScheduleStore {
    private const val PREFS = "flexit_schedule"
    private const val KEY_ALWAYS_ON = "alwaysOn"
    private const val KEY_SCHEDULE_ENABLED = "scheduleEnabled"
    private const val KEY_START_TIME = "startTime"
    private const val KEY_END_TIME = "endTime"
    private const val KEY_NEXT_START = "nextStartAtMillis"
    private const val KEY_BASE_URL = "baseUrl"
    private const val KEY_DEVICE_CODE = "deviceCode"
    private const val LAUNCH_REQUEST_CODE = 1001
    private const val ALWAYS_ON_RETRY_MS = 30_000L
    private const val FOREGROUND_LAUNCH_DELAY_MS = 1_000L

    fun save(context: Context, args: Map<*, *>?) {
        if (args == null) return

        val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_BASE_URL, args[KEY_BASE_URL] as? String)
            .putString(KEY_DEVICE_CODE, args[KEY_DEVICE_CODE] as? String)
            .putBoolean(KEY_ALWAYS_ON, args[KEY_ALWAYS_ON] as? Boolean ?: true)
            .putBoolean(
                KEY_SCHEDULE_ENABLED,
                args[KEY_SCHEDULE_ENABLED] as? Boolean ?: false
            )
            .putString(KEY_START_TIME, args[KEY_START_TIME] as? String ?: "09:00")
            .putString(KEY_END_TIME, args[KEY_END_TIME] as? String ?: "22:00")
            .putLong(KEY_NEXT_START, numberAsLong(args[KEY_NEXT_START]) ?: 0L)

        editor.apply()
    }

    fun saveNextStart(context: Context, args: Map<*, *>?) {
        val nextStart = numberAsLong(args?.get(KEY_NEXT_START)) ?: return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_NEXT_START, nextStart)
            .apply()
    }

    fun shouldLaunchOnBoot(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) return false
        if (prefs.getBoolean(KEY_ALWAYS_ON, true)) return true
        return isScheduleActive(context)
    }

    fun scheduleConfigCheck(context: Context) {
        // Display config is delivered by the Flutter websocket service.
    }

    fun refreshFromBackend(context: Context): Boolean {
        return false
    }

    fun applyCurrentSchedule(context: Context) {
        scheduleConfigCheck(context)

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) {
            cancelLaunchAlarms(context)
            return
        }

        if (shouldLaunchOnBoot(context)) {
            scheduleForegroundLaunch(context)
            scheduleAlwaysOnRetry(context)
            launchApp(context)
            return
        }

        scheduleNextLaunch(context)
    }

    fun scheduleForegroundLaunch(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        scheduleLaunchAlarm(
            alarmManager,
            System.currentTimeMillis() + FOREGROUND_LAUNCH_DELAY_MS,
            launchPendingIntent(context)
        )
    }

    fun scheduleAlwaysOnRetry(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) return
        if (!prefs.getBoolean(KEY_ALWAYS_ON, true)) return

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = launchPendingIntent(context)
        val triggerAt = System.currentTimeMillis() + ALWAYS_ON_RETRY_MS

        scheduleLaunchAlarm(alarmManager, triggerAt, pendingIntent)
    }

    fun scheduleNextLaunch(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_SCHEDULE_ENABLED, false)) {
            cancelLaunchAlarms(context)
            return
        }

        if (isScheduleActive(context)) {
            launchApp(context)
            return
        }

        val nextStart = nextStartAtMillis(context)
        if (nextStart <= System.currentTimeMillis()) return

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = launchPendingIntent(context)

        scheduleLaunchAlarm(alarmManager, nextStart, pendingIntent)
    }

    fun cancelLaunchAlarms(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(launchPendingIntent(context))
    }

    private fun launchPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        return PendingIntent.getActivity(
            context,
            LAUNCH_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun scheduleLaunchAlarm(
        alarmManager: AlarmManager,
        triggerAt: Long,
        pendingIntent: PendingIntent
    ) {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarmManager.canScheduleExactAlarms()
            ) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAt, pendingIntent),
                    pendingIntent
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        } catch (_: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    private fun nextStartAtMillis(context: Context): Long {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val saved = prefs.getLong(KEY_NEXT_START, 0L)
        if (saved > System.currentTimeMillis()) return saved

        return computeNextStartAtMillis(
            prefs.getString(KEY_START_TIME, "09:00") ?: "09:00",
            prefs.getString(KEY_END_TIME, "22:00") ?: "22:00"
        )
    }

    private fun computeNextStartAtMillis(startValue: String, endValue: String): Long {
        val start = minutesOfDay(startValue, 9 * 60)
        val end = minutesOfDay(endValue, 22 * 60)
        if (start == end) return 0L

        val now = Calendar.getInstance()
        val current = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val startCalendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, start / 60)
            set(Calendar.MINUTE, start % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (start < end) {
            if (current >= start) startCalendar.add(Calendar.DAY_OF_YEAR, 1)
            return startCalendar.timeInMillis
        }

        if (current >= end) startCalendar.add(Calendar.DAY_OF_YEAR, 1)
        return startCalendar.timeInMillis
    }

    fun launchApp(context: Context) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "flexit:launch"
        )
        wakeLock.acquire(10_000L)

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: run {
                if (wakeLock.isHeld) wakeLock.release()
                return
            }
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        context.startActivity(launchIntent)
        if (wakeLock.isHeld) wakeLock.release()
    }

    private fun isScheduleActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val start = minutesOfDay(prefs.getString(KEY_START_TIME, "09:00"), 9 * 60)
        val end = minutesOfDay(prefs.getString(KEY_END_TIME, "22:00"), 22 * 60)
        if (start == end) return true

        val calendar = Calendar.getInstance()
        val current = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)

        return if (start < end) {
            current >= start && current < end
        } else {
            current >= start || current < end
        }
    }

    private fun minutesOfDay(value: String?, fallback: Int): Int {
        val parts = value?.split(":") ?: return fallback
        if (parts.size != 2) return fallback

        val hour = parts[0].toIntOrNull() ?: return fallback
        val minute = parts[1].toIntOrNull() ?: return fallback

        return hour * 60 + minute
    }

    private fun numberAsLong(value: Any?): Long? {
        return when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Double -> value.toLong()
            is Float -> value.toLong()
            else -> null
        }
    }
}
