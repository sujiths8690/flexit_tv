package com.flexit.display

import android.Manifest
import android.provider.Settings
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.Collections
import java.util.Locale

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        requestLocalMediaPermissions()

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.flexit.display/local_media"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanLocalMedia" -> result.success(scanLocalMedia())
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.flexit.display/device_info"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> result.success(deviceInfo())
                else -> result.notImplemented()
            }
        }
    }

    private fun deviceInfo(): Map<String, Any?> {
        val displayMetrics = resources.displayMetrics

        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "product" to Build.PRODUCT,
            "deviceName" to Build.DEVICE,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "buildId" to Build.ID,
            "buildDisplay" to Build.DISPLAY,
            "fingerprint" to Build.FINGERPRINT,
            "serialNumber" to deviceSerial(),
            "androidId" to Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID),
            "macAddress" to localMacAddress(),
            "ipAddress" to localIpAddress(),
            "screenWidth" to displayMetrics.widthPixels,
            "screenHeight" to displayMetrics.heightPixels,
            "screenPixelRatio" to displayMetrics.density,
            "platform" to "android",
            "osVersion" to System.getProperty("os.version"),
            "appVersion" to packageManager.getPackageInfo(packageName, 0).versionName
        )
    }

    private fun deviceSerial(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Build.getSerial() else Build.SERIAL
        } catch (_: Exception) {
            null
        }
    }

    private fun localMacAddress(): String? {
        return try {
            val interfaces = Collections.list(NetworkInterface.getNetworkInterfaces())
            val networkInterface = interfaces.firstOrNull {
                it.name.equals("wlan0", ignoreCase = true) ||
                    it.name.equals("eth0", ignoreCase = true)
            } ?: interfaces.firstOrNull { !it.isLoopback && it.hardwareAddress != null }
            networkInterface?.hardwareAddress?.joinToString(":") {
                "%02X".format(Locale.US, it.toInt() and 0xFF)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun localIpAddress(): String? {
        return try {
            Collections.list(NetworkInterface.getNetworkInterfaces())
                .asSequence()
                .filter { !it.isLoopback && it.isUp }
                .flatMap { Collections.list(it.inetAddresses).asSequence() }
                .filterIsInstance<Inet4Address>()
                .firstOrNull { !it.isLoopbackAddress }
                ?.hostAddress
        } catch (_: Exception) {
            null
        }
    }

    private fun scanLocalMedia(): List<Map<String, Any>> {
        val folders = linkedSetOf<File>()

        File("/storage").listFiles()?.forEach { root ->
            if (!root.isDirectory) return@forEach
            if (root.name.equals("emulated", ignoreCase = true)) return@forEach
            folders.add(File(root, "flexit/media"))
            folders.add(File(root, "Flexit/media"))
            folders.add(File(root, "FLEXIT/media"))
        }

        getExternalFilesDirs(null).filterNotNull().forEach { appDir ->
            folders.add(File(appDir, "flexit/media"))
            appDir.parentFile?.parentFile?.parentFile?.let { volumeRoot ->
                folders.add(File(volumeRoot, "flexit/media"))
            }
        }

        val files = folders
            .filter { it.exists() && it.isDirectory }
            .flatMap { folder ->
                folder.walkTopDown()
                    .maxDepth(2)
                    .filter { it.isFile && it.isSupportedMedia() }
                    .toList()
            }
            .distinctBy { it.absolutePath }
            .sortedBy { it.name.lowercase() }

        return files.mapIndexed { index, file ->
            mapOf(
                "id" to -1 - index,
                "fileName" to file.name,
                "url" to file.toURI().toString(),
                "type" to file.mediaType()
            )
        }
    }

    private fun requestLocalMediaPermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.READ_MEDIA_IMAGES,
                Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }

        requestPermissions(permissions, 2401)
    }

    private fun File.isSupportedMedia(): Boolean {
        val name = this.name.lowercase()
        return name.endsWith(".jpg") ||
            name.endsWith(".jpeg") ||
            name.endsWith(".png") ||
            name.endsWith(".webp") ||
            name.endsWith(".mp4") ||
            name.endsWith(".m4v") ||
            name.endsWith(".mov") ||
            name.endsWith(".mkv")
    }

    private fun File.mediaType(): String {
        val name = this.name.lowercase()
        return if (
            name.endsWith(".mp4") ||
            name.endsWith(".m4v") ||
            name.endsWith(".mov") ||
            name.endsWith(".mkv")
        ) {
            "video"
        } else {
            "image"
        }
    }
}
