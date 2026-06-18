package com.flexit.display

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import javax.crypto.KeyGenerator
import javax.crypto.Mac
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

object SubscriptionExpiryStore {
    private const val KEY_ALIAS = "flexit_subscription_entitlement_v1"
    private const val FILE_NAME = "subscription_entitlement.dat"
    private const val NO_EXPIRY = -1L

    fun update(context: Context, values: Map<*, *>?): Map<String, Any> {
        val now = System.currentTimeMillis()
        val serverTime =
            (values?.get("serverTimeMillis") as? Number)?.toLong() ?: now
        val record = Record(
            deviceCode = values?.get("deviceCode")?.toString().orEmpty(),
            expiresAtMillis = (values?.get("expiresAtMillis") as? Number)?.toLong() ?: NO_EXPIRY,
            blocked = values?.get("blocked") == true,
            serverTimeAtSave = serverTime,
            elapsedRealtimeAtSave = SystemClock.elapsedRealtime(),
            bootCount = bootCount(context),
            maxObservedTime = serverTime
        )
        write(context, record)
        return evaluate(context, record)
    }

    fun status(context: Context): Map<String, Any> {
        val file = entitlementFile(context)
        if (!file.exists()) return mapOf("expired" to false, "stored" to false)

        val record = read(context) ?: return mapOf(
            "expired" to true,
            "stored" to true,
            "tampered" to true
        )
        return evaluate(context, record)
    }

    private fun evaluate(context: Context, record: Record): Map<String, Any> {
        val wallNow = System.currentTimeMillis()
        val sameBoot = record.bootCount == bootCount(context)
        val clockRolledBack = !sameBoot && wallNow + 300_000L < record.maxObservedTime
        val monotonicNow = if (sameBoot) {
            record.serverTimeAtSave +
                (SystemClock.elapsedRealtime() - record.elapsedRealtimeAtSave).coerceAtLeast(0L)
        } else {
            wallNow
        }
        val effectiveNow = if (sameBoot) {
            maxOf(monotonicNow, record.maxObservedTime)
        } else {
            maxOf(wallNow, record.maxObservedTime)
        }
        val updated = record.copy(maxObservedTime = effectiveNow)
        if (updated != record) write(context, updated)
        val expired = clockRolledBack || record.blocked ||
            (record.expiresAtMillis != NO_EXPIRY && effectiveNow >= record.expiresAtMillis)
        return mapOf(
            "expired" to expired,
            "stored" to true,
            "clockRolledBack" to clockRolledBack,
            "expiresAtMillis" to record.expiresAtMillis,
            "effectiveNowMillis" to effectiveNow
        )
    }

    private fun write(context: Context, record: Record) {
        val payload = record.payload()
        val json = JSONObject()
            .put("payload", payload)
            .put("signature", sign(context, payload))
        val target = entitlementFile(context)
        val temporary = File(target.parentFile, "$FILE_NAME.tmp")
        temporary.writeText(json.toString(), Charsets.UTF_8)
        if (!temporary.renameTo(target)) {
            target.writeText(json.toString(), Charsets.UTF_8)
            temporary.delete()
        }
    }

    private fun read(context: Context): Record? {
        return try {
            val json = JSONObject(entitlementFile(context).readText(Charsets.UTF_8))
            val payload = json.getString("payload")
            val expected = sign(context, payload)
            val actual = json.getString("signature")
            if (!MessageDigest.isEqual(expected.toByteArray(), actual.toByteArray())) {
                null
            } else {
                Record.fromPayload(payload)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun sign(context: Context, payload: String): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(secretKey(context))
        return Base64.encodeToString(
            mac.doFinal(payload.toByteArray(Charsets.UTF_8)),
            Base64.NO_WRAP
        )
    }

    private fun secretKey(context: Context): SecretKey {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
            (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
            val generator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_HMAC_SHA256,
                "AndroidKeyStore"
            )
            generator.init(
                KeyGenParameterSpec.Builder(
                    KEY_ALIAS,
                    KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                ).setDigests(KeyProperties.DIGEST_SHA256).build()
            )
            return generator.generateKey()
        }

        val androidId = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        ).orEmpty()
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest("${context.packageName}:$androidId:$KEY_ALIAS".toByteArray())
        return SecretKeySpec(bytes, "HmacSHA256")
    }

    private fun entitlementFile(context: Context) = File(context.noBackupFilesDir, FILE_NAME)

    private fun bootCount(context: Context): Int = try {
        Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT)
    } catch (_: Exception) {
        -1
    }

    private data class Record(
        val deviceCode: String,
        val expiresAtMillis: Long,
        val blocked: Boolean,
        val serverTimeAtSave: Long,
        val elapsedRealtimeAtSave: Long,
        val bootCount: Int,
        val maxObservedTime: Long
    ) {
        fun payload(): String = listOf(
            "1",
            Base64.encodeToString(deviceCode.toByteArray(Charsets.UTF_8), Base64.NO_WRAP),
            expiresAtMillis,
            blocked,
            serverTimeAtSave,
            elapsedRealtimeAtSave,
            bootCount,
            maxObservedTime
        ).joinToString("|")

        companion object {
            fun fromPayload(payload: String): Record? {
                val parts = payload.split('|')
                if (parts.size != 8 || parts[0] != "1") return null
                return try {
                    Record(
                        deviceCode = String(
                            Base64.decode(parts[1], Base64.NO_WRAP),
                            Charsets.UTF_8
                        ),
                        expiresAtMillis = parts[2].toLong(),
                        blocked = parts[3].toBooleanStrict(),
                        serverTimeAtSave = parts[4].toLong(),
                        elapsedRealtimeAtSave = parts[5].toLong(),
                        bootCount = parts[6].toInt(),
                        maxObservedTime = parts[7].toLong()
                    )
                } catch (_: Exception) {
                    null
                }
            }
        }
    }
}
