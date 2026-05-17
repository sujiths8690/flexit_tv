package com.flexit.display

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.flexit.display/schedule"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSchedule" -> {
                    ScheduleStore.save(this, call.arguments as? Map<*, *>)
                    ScheduleStore.scheduleNextLaunch(this)
                    ScheduleStore.scheduleConfigCheck(this)
                    ScheduleStore.scheduleAlwaysOnRetry(this)
                    result.success(null)
                }
                "backgroundUntilNextStart" -> {
                    ScheduleStore.saveNextStart(this, call.arguments as? Map<*, *>)
                    ScheduleStore.scheduleNextLaunch(this)
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
