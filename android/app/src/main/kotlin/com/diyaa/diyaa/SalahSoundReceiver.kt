package com.diyaa.diyaa

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.PowerManager
import java.io.IOException

/**
 * BroadcastReceiver that plays the Salah 'ala Al-Nabi sound via MediaPlayer
 * when a native AlarmManager alarm fires, and auto-reschedules for the next
 * interval.
 *
 * Key design decisions:
 * - Uses goAsync() to extend the BroadcastReceiver lifecycle beyond the
 *   normal ~10 second kill window. This ensures MediaPlayer has time to
 *   prepare and play the sound even when the app process is dead.
 * - After playing the sound, auto-reschedules the alarm for the next
 *   interval (scheduledTimeMillis + intervalMinutes * 60000). This provides
 *   daily repetition without relying on zonedSchedule()'s
 *   matchDateTimeComponents mechanism.
 * - Checks SharedPreferences (salah_nabi_enabled) before playing. If the
 *   user disabled Salah Nabi in the app, the alarm is cancelled instead
 *   of rescheduled. This handles the case where the app schedules alarms
 *   but the user later disables them — the native alarm checks the
 *   preference at fire time.
 * - Acquires a PARTIAL_WAKE_LOCK to ensure the device stays awake during
 *   sound playback. This is critical because the device may be in
 *   Doze/sleep mode when the alarm fires.
 */
class SalahSoundReceiver : BroadcastReceiver() {
    companion object {
        private const val PREFS_NAME = "diyaa_salah_prefs"
        private const val KEY_ENABLED = "salah_nabi_enabled"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val soundAsset = intent.getStringExtra("soundAsset") ?: return
        val overrideSilent = intent.getBooleanExtra("overrideSilent", false)
        val alarmId = intent.getIntExtra("id", 0)
        val intervalMinutes = intent.getIntExtra("intervalMinutes", 0)
        val scheduledTimeMillis = intent.getLongExtra("scheduledTimeMillis", 0L)

        // Use goAsync() to extend the BroadcastReceiver lifecycle.
        // Without this, the system can kill the process ~10 seconds after
        // onReceive() returns, which may be before MediaPlayer finishes
        // preparing/playing. goAsync() gives us up to ~30 seconds.
        val pendingResult = goAsync()

        // Check SharedPreferences — if the user disabled Salah Nabi in the
        // app, cancel this alarm and don't reschedule. This handles the case
        // where the app schedules alarms but the user later disables them.
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean(KEY_ENABLED, false)

        if (!isEnabled) {
            // User disabled Salah Nabi — cancel this alarm and don't reschedule
            cancelAlarmById(context, alarmId)
            pendingResult.finish()
            return
        }

        // Acquire a WakeLock to ensure the device stays awake during sound playback.
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "diyaa:SalahSoundWakeLock:$alarmId"
        )
        wakeLock.acquire(30_000L) // Max 30 seconds for sound playback + reschedule

        // Play the sound via MediaPlayer
        val mediaPlayer = MediaPlayer()
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(
                    if (overrideSilent) AudioAttributes.USAGE_ALARM
                    else AudioAttributes.USAGE_NOTIFICATION
                )
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            mediaPlayer.setAudioAttributes(audioAttributes)

            val resourceId = context.resources.getIdentifier(
                soundAsset, "raw", context.packageName
            )
            if (resourceId != 0) {
                val afd = context.resources.openRawResourceFd(resourceId)
                mediaPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()

                mediaPlayer.setOnCompletionListener { mp ->
                    mp.release()
                    rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                        soundAsset, overrideSilent)
                    if (wakeLock.isHeld) wakeLock.release()
                    pendingResult.finish()
                }
                mediaPlayer.setOnErrorListener { mp, _, _ ->
                    mp.release()
                    // Still reschedule even if playback failed — don't break the chain
                    rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                        soundAsset, overrideSilent)
                    if (wakeLock.isHeld) wakeLock.release()
                    pendingResult.finish()
                    true
                }
                mediaPlayer.prepare()
                mediaPlayer.start()
            } else {
                // Resource not found — still reschedule
                mediaPlayer.release()
                rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                    soundAsset, overrideSilent)
                if (wakeLock.isHeld) wakeLock.release()
                pendingResult.finish()
            }
        } catch (e: IOException) {
            mediaPlayer.release()
            rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                soundAsset, overrideSilent)
            if (wakeLock.isHeld) wakeLock.release()
            pendingResult.finish()
        } catch (e: Exception) {
            mediaPlayer.release()
            rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                soundAsset, overrideSilent)
            if (wakeLock.isHeld) wakeLock.release()
            pendingResult.finish()
        }
    }

    /**
     * Auto-reschedule the alarm for the next interval.
     * Calculates nextFireTime = scheduledTimeMillis + intervalMinutes * 60000.
     * If nextFireTime is in the past (e.g., device was in deep Doze), adds
     * intervalMinutes increments until it's in the future.
     */
    private fun rescheduleAlarm(
        context: Context,
        alarmId: Int,
        scheduledTimeMillis: Long,
        intervalMinutes: Int,
        soundAsset: String,
        overrideSilent: Boolean
    ) {
        if (intervalMinutes <= 0) return // Don't reschedule if no interval

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intervalMillis = intervalMinutes * 60_000L

        // Calculate next fire time: original scheduled time + one interval
        var nextFireTime = scheduledTimeMillis + intervalMillis

        // If nextFireTime is in the past (device was in deep Doze/sleep),
        // keep adding intervals until we get a future time
        val now = System.currentTimeMillis()
        while (nextFireTime <= now) {
            nextFireTime += intervalMillis
        }

        // Create new PendingIntent with updated scheduledTimeMillis
        val newIntent = Intent(context, SalahSoundReceiver::class.java).apply {
            putExtra("id", alarmId)
            putExtra("soundAsset", soundAsset)
            putExtra("overrideSilent", overrideSilent)
            putExtra("intervalMinutes", intervalMinutes)
            putExtra("scheduledTimeMillis", nextFireTime)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId + 10000, // Offset to avoid collision with flutter_local_notifications
            newIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Schedule the next alarm with the same exact-alarm strategy
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (!alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    nextFireTime,
                    pendingIntent
                )
                return
            }
        }

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            nextFireTime,
            pendingIntent
        )
    }

    /**
     * Cancel an alarm by its alarm ID. Used when SharedPreferences indicates
     * Salah Nabi is disabled.
     */
    private fun cancelAlarmById(context: Context, alarmId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, SalahSoundReceiver::class.java)
        for (requestCode in listOf(alarmId + 10000, alarmId)) {
            val pendingIntent = PendingIntent.getBroadcast(
                context,
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
}