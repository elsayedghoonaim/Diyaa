package com.diyaa.diyaa

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity with MethodChannel handler for native Salah sound alarms.
 *
 * Handles three MethodChannel calls from Dart:
 * - scheduleSalahSoundAlarm: Schedules an AlarmManager alarm that fires
 *   SalahSoundReceiver at the specified time, which plays the sound via
 *   MediaPlayer directly. Also writes salah_nabi_enabled=true to
 *   SharedPreferences so SalahSoundReceiver can check if reminders are
 *   still enabled at fire time.
 * - cancelSalahSoundAlarm: Cancels a previously scheduled native alarm.
 * - setSalahNabiEnabled: Writes the enabled state to SharedPreferences.
 *   When enabled=false, SalahSoundReceiver will cancel its alarm at fire
 *   time instead of rescheduling, breaking the auto-reschedule chain.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "diyaa_alarm_channel"

    companion object {
        private const val PREFS_NAME = "diyaa_salah_prefs"
        private const val KEY_ENABLED = "salah_nabi_enabled"
        private const val KEY_SOUND_ASSET = "salah_nabi_sound_asset"
        private const val KEY_OVERRIDE_SILENT = "salah_nabi_override_silent"
        private const val KEY_INTERVAL_MINUTES = "salah_nabi_interval_minutes"
        private const val TAG = "DiyaaMainActivity"
    }

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
                        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 0

                        // DIAGNOSTIC: Write full Salah Nabi configuration to SharedPreferences.
                        // CRITICAL FIX: Use commit() instead of apply() to ensure synchronous
                        // disk write. apply() is asynchronous — data is written to an in-memory
                        // cache and scheduled for disk write later. If the app process is killed
                        // before the disk write completes, the data is LOST. When
                        // SalahSoundReceiver fires in a freshly-spawned process, it reads
                        // salah_nabi_enabled from disk and gets the default false, causing it
                        // to CANCEL the alarm instead of playing sound. This is the root cause
                        // of the "test works but scheduled reminders fail" discrepancy:
                        // - Test path: app is alive → SharedPreferences in-memory cache has true
                        // - Scheduled path: app process dead → disk has stale false → alarm cancelled
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val commitResult = prefs.edit()
                            .putBoolean(KEY_ENABLED, true)
                            .putString(KEY_SOUND_ASSET, soundAsset)
                            .putBoolean(KEY_OVERRIDE_SILENT, overrideSilent)
                            .putInt(KEY_INTERVAL_MINUTES, intervalMinutes)
                            .commit()  // DIAGNOSTIC: commit() = synchronous disk write
                        Log.d(TAG, "scheduleSalahSoundAlarm: SharedPreferences commit() result=$commitResult "
                            + "(id=$id, sound=$soundAsset, overrideSilent=$overrideSilent, "
                            + "interval=$intervalMinutes)")

                        scheduleAlarm(id, scheduledTime, soundAsset, overrideSilent, intervalMinutes)
                        result.success(true)
                    }
                    "cancelSalahSoundAlarm" -> {
                        val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error(
                            "INVALID_ARGS", "Missing 'id' argument", null
                        )
                        cancelAlarm(id)
                        result.success(true)
                    }
                    "setSalahNabiEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: return@setMethodCallHandler result.error(
                            "INVALID_ARGS", "Missing 'enabled' argument", null
                        )
                        // DIAGNOSTIC: Use commit() instead of apply() for synchronous disk write.
                        // Same root cause as scheduleSalahSoundAlarm — apply() can lose data
                        // on process death, causing SalahSoundReceiver to read stale false.
                        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val commitResult = prefs.edit().putBoolean(KEY_ENABLED, enabled).commit()
                        Log.d(TAG, "setSalahNabiEnabled: SharedPreferences commit() result=$commitResult "
                            + "(enabled=$enabled)")
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Schedule an AlarmManager alarm that fires SalahSoundReceiver at the
     * specified time. Passes intervalMinutes and scheduledTimeMillis as
     * Intent extras so SalahSoundReceiver can auto-reschedule after playing.
     */
    private fun scheduleAlarm(
        id: Int,
        scheduledTime: Long,
        soundAsset: String,
        overrideSilent: Boolean,
        intervalMinutes: Int
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    scheduledTime,
                    createPendingIntent(id, soundAsset, overrideSilent, intervalMinutes, scheduledTime)
                )
                return
            }
        }

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            scheduledTime,
            createPendingIntent(id, soundAsset, overrideSilent, intervalMinutes, scheduledTime)
        )
    }

    /**
     * Cancel a previously scheduled native alarm. Tries both possible
     * request codes (id + 10000 and id) to ensure cancellation.
     */
    private fun cancelAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SalahSoundReceiver::class.java)
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
     * Create a PendingIntent that fires SalahSoundReceiver with all
     * alarm parameters including intervalMinutes and scheduledTimeMillis
     * for auto-rescheduling.
     */
    private fun createPendingIntent(
        id: Int,
        soundAsset: String,
        overrideSilent: Boolean,
        intervalMinutes: Int,
        scheduledTimeMillis: Long
    ): PendingIntent {
        val intent = Intent(this, SalahSoundReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("soundAsset", soundAsset)
            putExtra("overrideSilent", overrideSilent)
            putExtra("intervalMinutes", intervalMinutes)
            putExtra("scheduledTimeMillis", scheduledTimeMillis)
        }
        return PendingIntent.getBroadcast(
            this,
            id + 10000, // Offset to avoid collision with flutter_local_notifications IDs
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
