package com.diyaa.diyaa

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity with MethodChannel handler for native Salah sound alarms.
 *
 * This handles two MethodChannel calls from Dart:
 * - scheduleSalahSoundAlarm: Schedules an AlarmManager alarm that fires
 *   SalahSoundReceiver at the specified time, which plays the sound via
 *   MediaPlayer directly (bypassing the unreliable notification channel sound).
 * - cancelSalahSoundAlarm: Cancels a previously scheduled native alarm.
 *
 * The native alarm uses setExactAndAllowWhileIdle (or setAndAllowWhileIdle
 * as fallback on Android 12+ without exact alarm permission) to ensure the
 * alarm fires even in Doze mode.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "diyaa_alarm_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleSalahSoundAlarm" -> {
                        val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error(
                            "INVALID_ARGS", "Missing 'id' argument", null
                        )
                        val scheduledTime = call.argument<Long>("scheduledTime") ?: return@setMethodCallHandler result.error(
                            "INVALID_ARGS", "Missing 'scheduledTime' argument", null
                        )
                        val soundAsset = call.argument<String>("soundAsset") ?: return@setMethodCallHandler result.error(
                            "INVALID_ARGS", "Missing 'soundAsset' argument", null
                        )
                        val overrideSilent = call.argument<Boolean>("overrideSilent") ?: false

                        scheduleAlarm(id, scheduledTime, soundAsset, overrideSilent)
                        result.success(true)
                    }
                    "cancelSalahSoundAlarm" -> {
                        val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error(
                            "INVALID_ARGS", "Missing 'id' argument", null
                        )
                        cancelAlarm(id)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Schedule an AlarmManager alarm that fires SalahSoundReceiver at the
     * specified time. Uses setExactAndAllowWhileIdle for exact alarms that
     * fire even in Doze mode, with fallback to inexact alarms on Android 12+
     * if the SCHEDULE_EXACT_ALARM permission is not granted.
     */
    private fun scheduleAlarm(id: Int, scheduledTime: Long, soundAsset: String, overrideSilent: Boolean) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // Check for exact alarm permission on Android 12+ (API 31+).
        // On Android 13+ (API 33+), USE_EXACT_ALARM is auto-granted for
        // alarm/prayer/calendar apps, but SCHEDULE_EXACT_ALARM requires
        // user approval. If neither is available, fall back to inexact alarm.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                // Fall back to inexact alarm — still better than no sound at all.
                // setAndAllowWhileIdle fires approximately at the scheduled time
                // and works during Doze mode (though with some delay).
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    scheduledTime,
                    createPendingIntent(id, soundAsset, overrideSilent)
                )
                return
            }
        }

        // Schedule exact alarm that fires even in Doze mode.
        // setExactAndAllowWhileIdle fires at the exact scheduled time
        // and is not restricted by Doze mode.
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            scheduledTime,
            createPendingIntent(id, soundAsset, overrideSilent)
        )
    }

    /**
     * Cancel a previously scheduled native alarm. Tries both possible
     * request codes (id and id + 10000) to ensure cancellation, since
     * the PendingIntent request code uses an offset to avoid collision
     * with flutter_local_notifications IDs.
     */
    private fun cancelAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SalahSoundReceiver::class.java)
        // Try both possible request codes to ensure cancellation:
        // - id + 10000: the actual request code used for native alarms
        // - id: fallback in case of any inconsistency
        for (requestCode in listOf(id + 10000, id)) {
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                requestCode,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        }
    }

    /**
     * Create a PendingIntent that fires SalahSoundReceiver with the
     * alarm parameters. Uses id + 10000 as the request code to avoid
     * collision with flutter_local_notifications which uses the
     * notification ID directly as the request code.
     */
    private fun createPendingIntent(id: Int, soundAsset: String, overrideSilent: Boolean): PendingIntent {
        val intent = Intent(this, SalahSoundReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("soundAsset", soundAsset)
            putExtra("overrideSilent", overrideSilent)
        }
        return PendingIntent.getBroadcast(
            this,
            id + 10000, // Offset to avoid collision with flutter_local_notifications IDs
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
