package com.diyaa.diyaa

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.PowerManager
import java.util.Calendar

/**
 * BroadcastReceiver that reschedules native Salah sound alarms after a
 * device reboot or app update.
 *
 * When Android reboots, all AlarmManager alarms are lost. Since we skip
 * zonedSchedule() on Android (to avoid the unwanted visible notification),
 * the flutter_local_notifications boot receiver won't reschedule our native
 * alarms. This receiver reads the Salah Nabi configuration from SharedPreferences
 * and reschedules all native alarms for the current/next day.
 *
 * The configuration is written to SharedPreferences by MainActivity when
 * scheduleSalahSoundAlarm or setSalahNabiEnabled is called from Dart.
 */
class SalahBootReceiver : BroadcastReceiver() {
    companion object {
        private const val PREFS_NAME = "diyaa_salah_prefs"
        private const val KEY_ENABLED = "salah_nabi_enabled"
        private const val KEY_SOUND_ASSET = "salah_nabi_sound_asset"
        private const val KEY_OVERRIDE_SILENT = "salah_nabi_override_silent"
        private const val KEY_INTERVAL_MINUTES = "salah_nabi_interval_minutes"
        private const val ID_BASE = 60
        private const val ID_MAX = 400
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == null) return

        val actions = listOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON"
        )
        if (!actions.contains(intent.action)) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean(KEY_ENABLED, false)

        if (!isEnabled) return // Salah Nabi is disabled — don't reschedule

        val soundAsset = prefs.getString(KEY_SOUND_ASSET, "salah_nabi") ?: "salah_nabi"
        val overrideSilent = prefs.getBoolean(KEY_OVERRIDE_SILENT, false)
        val intervalMinutes = prefs.getInt(KEY_INTERVAL_MINUTES, 5)

        if (intervalMinutes <= 0) return // Invalid interval — don't reschedule

        // Acquire a WakeLock to ensure the device stays awake during rescheduling
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "diyaa:SalahBootWakeLock"
        )
        wakeLock.acquire(10_000L) // Max 10 seconds for rescheduling

        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val now = Calendar.getInstance()
            val minutesSinceMidnight = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

            // Calculate the first slot time: next interval boundary after current time
            val firstSlotMinutes = ((minutesSinceMidnight / intervalMinutes) + 1) * intervalMinutes
            val slotsPerDay = (24 * 60) / intervalMinutes
            val totalSlots = slotsPerDay.coerceAtMost(ID_MAX - ID_BASE + 1)

            var scheduledCount = 0
            for (slot in 0 until totalSlots) {
                val slotMinutes = (firstSlotMinutes + slot * intervalMinutes) % (24 * 60)
                val hour = slotMinutes / 60
                val minute = slotMinutes % 60

                // Calculate the fire time for this slot
                val fireAt = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }

                // If the fire time is in the past, schedule for tomorrow
                if (fireAt.timeInMillis <= System.currentTimeMillis()) {
                    fireAt.add(Calendar.DAY_OF_YEAR, 1)
                }

                val id = ID_BASE + slot
                val scheduledTimeMillis = fireAt.timeInMillis

                // Create PendingIntent with all config for auto-rescheduling
                val alarmIntent = Intent(context, SalahSoundReceiver::class.java).apply {
                    putExtra("id", id)
                    putExtra("soundAsset", soundAsset)
                    putExtra("overrideSilent", overrideSilent)
                    putExtra("intervalMinutes", intervalMinutes)
                    putExtra("scheduledTimeMillis", scheduledTimeMillis)
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    id + 10000,
                    alarmIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // Schedule the alarm
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (!alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTimeMillis,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTimeMillis,
                            pendingIntent
                        )
                    }
                } else {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        scheduledTimeMillis,
                        pendingIntent
                    )
                }

                scheduledCount++
            }

            android.util.Log.d("Diyaa", "[SalahBoot] Rescheduled $scheduledCount native alarms "
                + "(every $intervalMinutes min, sound=$soundAsset, overrideSilent=$overrideSilent)")
        } finally {
            if (wakeLock.isHeld) wakeLock.release()
        }
    }
}