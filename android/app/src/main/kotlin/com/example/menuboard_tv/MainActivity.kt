package com.flexit.display

import android.Manifest
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.provider.Settings
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.net.Inet4Address
import java.net.NetworkInterface
import java.security.MessageDigest
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
            folders.addMediaFolders(root)
        }

        getExternalFilesDirs(null).filterNotNull().forEach { appDir ->
            externalVolumeRoot(appDir)?.let { volumeRoot ->
                if (volumeRoot.isEmulatedStorage()) return@let
                folders.addMediaFolders(volumeRoot)
            }
        }

        val files = folders
            .filter { it.exists() && it.isDirectory }
            .flatMap { folder ->
                folder.walkTopDown()
                    .maxDepth(2)
                    .filter {
                        it.isFile &&
                            it.isSupportedMedia() &&
                            it.hasUsableSize() &&
                            it.isAllowedDuration()
                    }
                    .toList()
            }
            .distinctBy { it.absolutePath }
            .sortedBy { it.name.lowercase() }

        return files.mapIndexed { index, file ->
            val playbackFile = file.playbackFile()
            mapOf(
                "id" to -1 - index,
                "fileName" to file.name,
                "url" to playbackFile.toURI().toString(),
                "type" to file.mediaType()
            )
        }
    }

    private fun MutableSet<File>.addMediaFolders(root: File) {
        foldersFor(root).forEach { add(it) }
    }

    private fun foldersFor(root: File): List<File> {
        val appFolders = listOf("flexit", "Flexit", "FLEXIT")
        val mediaFolders = listOf("media", "Media", "MEDIA")
        return appFolders.flatMap { appFolder ->
            mediaFolders.map { mediaFolder -> File(root, "$appFolder/$mediaFolder") }
        }
    }

    private fun externalVolumeRoot(appDir: File): File? {
        var current: File? = appDir
        repeat(4) {
            current = current?.parentFile
        }
        return current
    }

    private fun File.isEmulatedStorage(): Boolean {
        val path = absolutePath.lowercase()
        return path == "/storage/emulated" || path.startsWith("/storage/emulated/")
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

    private fun File.hasUsableSize(): Boolean {
        val name = this.name.lowercase()
        val minBytes = if (
            name.endsWith(".mp4") ||
            name.endsWith(".m4v") ||
            name.endsWith(".mov") ||
            name.endsWith(".mkv")
        ) {
            1024L
        } else {
            512L
        }
        return length() >= minBytes
    }

    private fun File.isAllowedDuration(): Boolean {
        if (mediaType() != "video") return true
        val durationMs = videoDurationMs() ?: return false
        return durationMs <= 60_000L
    }

    private fun File.videoDurationMs(): Long? {
        return try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(absolutePath)
            val raw = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )
            retriever.release()
            raw?.toLongOrNull()
        } catch (_: Exception) {
            null
        }
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

    private fun File.playbackFile(): File {
        if (mediaType() != "image") return this
        return downscaledImageFile(this) ?: this
    }

    private fun downscaledImageFile(source: File): File? {
        return try {
            val outputDir = File(cacheDir, "flexit_media_cache").apply { mkdirs() }
            val output = File(outputDir, "${source.cacheKey()}.jpg")
            if (output.exists() && output.length() > 1024L) return output

            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(source.absolutePath, bounds)
            val sourceWidth = bounds.outWidth
            val sourceHeight = bounds.outHeight
            if (sourceWidth <= 0 || sourceHeight <= 0) return null

            val targetWidth = 1920
            val targetHeight = 1080
            val options = BitmapFactory.Options().apply {
                inSampleSize = sampleSizeFor(sourceWidth, sourceHeight, targetWidth, targetHeight)
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }

            val bitmap = BitmapFactory.decodeFile(source.absolutePath, options) ?: return null
            val scaled = bitmap.scaledToFit(targetWidth, targetHeight)
            FileOutputStream(output).use { stream ->
                scaled.compress(Bitmap.CompressFormat.JPEG, 95, stream)
            }
            if (scaled !== bitmap) scaled.recycle()
            bitmap.recycle()
            output
        } catch (_: Exception) {
            null
        }
    }

    private fun sampleSizeFor(
        width: Int,
        height: Int,
        targetWidth: Int,
        targetHeight: Int
    ): Int {
        var sample = 1
        while ((width / sample) > targetWidth * 2 || (height / sample) > targetHeight * 2) {
            sample *= 2
        }
        return sample
    }

    private fun Bitmap.scaledToFit(maxWidth: Int, maxHeight: Int): Bitmap {
        if (width <= maxWidth && height <= maxHeight) return this
        val scale = minOf(maxWidth.toFloat() / width, maxHeight.toFloat() / height)
        val scaledWidth = (width * scale).toInt().coerceAtLeast(1)
        val scaledHeight = (height * scale).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(this, scaledWidth, scaledHeight, true)
    }

    private fun File.cacheKey(): String {
        val raw = "image-cache-v2-1080p-q95:$absolutePath:${length()}:${lastModified()}"
        val digest = MessageDigest.getInstance("SHA-1").digest(raw.toByteArray())
        return digest.joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }
}
