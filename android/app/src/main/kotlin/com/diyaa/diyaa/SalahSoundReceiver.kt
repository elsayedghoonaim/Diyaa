package com.diyaa.diyaa

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.PowerManager
import android.util.Log
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
 * - Requests AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK before playing to ensure
 *   the sound is audible even when another app holds audio focus.
 * - Uses USAGE_ALARM when overrideSilent=true (bypasses DND/silent mode)
 *   and USAGE_MEDIA when overrideSilent=false (matches the test path's
 *   volume stream — STREAM_MUSIC). The notification channel sound is the
 *   PRIMARY mechanism; this MediaPlayer is BACKUP for DND/silent override.
 */
class SalahSoundReceiver : BroadcastReceiver() {
    companion object {
        private const val PREFS_NAME = "diyaa_salah_prefs"
        private const val KEY_ENABLED = "salah_nabi_enabled"
        private const val TAG = "DiyaaSalahSound"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val soundAsset = intent.getStringExtra("soundAsset") ?: return
        val overrideSilent = intent.getBooleanExtra("overrideSilent", false)
        val alarmId = intent.getIntExtra("id", 0)
        val intervalMinutes = intent.getIntExtra("intervalMinutes", 0)
        val scheduledTimeMillis = intent.getLongExtra("scheduledTimeMillis", 0L)

        Log.d(TAG, "onReceive: id=$alarmId, sound=$soundAsset, overrideSilent=$overrideSilent, "
            + "interval=$intervalMinutes, scheduledTime=$scheduledTimeMillis")

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

        // DIAGNOSTIC: Log the SharedPreferences state to validate whether
        // the apply() vs commit() persistence gap is causing salah_nabi_enabled
        // to read as false (default) when the app process is dead.
        Log.d(TAG, "SharedPreferences salah_nabi_enabled=$isEnabled (default=false)")
        Log.d(TAG, "SharedPreferences ALL: ${prefs.all}")

        if (!isEnabled) {
            // User disabled Salah Nabi — cancel this alarm and don't reschedule
            Log.w(TAG, "salah_nabi_enabled=false → CANCELING alarm id=$alarmId. "
                + "If user actually enabled this, the apply() persistence gap is the root cause.")
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
        Log.d(TAG, "WakeLock acquired for id=$alarmId")

        // Request audio focus before playing. Without audio focus,
        // USAGE_NOTIFICATION can be suppressed in Doze/background.
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val audioFocusResult = requestAudioFocus(audioManager, overrideSilent)
        Log.d(TAG, "Audio focus request result: $audioFocusResult "
            + "(AUDIOFOCUS_REQUEST_GRANTED=${AudioManager.AUDIOFOCUS_REQUEST_GRANTED})")

        // Play the sound via MediaPlayer
        val mediaPlayer = MediaPlayer()
        mediaPlayer.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK) // Ensure CPU stays awake during preparation & playback
        try {
            // Use USAGE_ALARM when overrideSilent=true (bypasses DND/silent mode),
            // and USAGE_NOTIFICATION_RINGTONE when overrideSilent=false.
            // Bypasses Android 9+ background media playback restrictions by using
            // a notification alert stream rather than the interactive music stream (USAGE_MEDIA).
            val usage = if (overrideSilent) {
                AudioAttributes.USAGE_ALARM
            } else {
                AudioAttributes.USAGE_NOTIFICATION_RINGTONE
            }
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(usage)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            mediaPlayer.setAudioAttributes(audioAttributes)

            val resourceId = context.resources.getIdentifier(
                soundAsset, "raw", context.packageName
            )
            if (resourceId != 0) {
                Log.d(TAG, "Resource found: $soundAsset → resourceId=$resourceId")
                val afd = context.resources.openRawResourceFd(resourceId)
                mediaPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()

                mediaPlayer.setOnCompletionListener { mp ->
                    Log.d(TAG, "MediaPlayer completed for id=$alarmId")
                    mp.release()
                    abandonAudioFocus(audioManager, overrideSilent)
                    rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                        soundAsset, overrideSilent)
                    if (wakeLock.isHeld) wakeLock.release()
                    pendingResult.finish()
                }
                mediaPlayer.setOnErrorListener { mp, what, extra ->
                    Log.e(TAG, "MediaPlayer error for id=$alarmId: what=$what, extra=$extra")
                    mp.release()
                    abandonAudioFocus(audioManager, overrideSilent)
                    // Still reschedule even if playback failed — don't break the chain
                    rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                        soundAsset, overrideSilent)
                    if (wakeLock.isHeld) wakeLock.release()
                    pendingResult.finish()
                    true
                }
                Log.d(TAG, "Preparing MediaPlayer for id=$alarmId...")
                mediaPlayer.prepare()
                Log.d(TAG, "MediaPlayer prepared, starting playback for id=$alarmId")
                mediaPlayer.start()
                Log.d(TAG, "MediaPlayer.start() called successfully for id=$alarmId")
            } else {
                Log.e(TAG, "Resource NOT found: $soundAsset → resourceId=0")
                // Resource not found — still reschedule
                mediaPlayer.release()
                abandonAudioFocus(audioManager, overrideSilent)
                rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                    soundAsset, overrideSilent)
                if (wakeLock.isHeld) wakeLock.release()
                pendingResult.finish()
            }
        } catch (e: IOException) {
            Log.e(TAG, "IOException during MediaPlayer for id=$alarmId: ${e.message}")
            mediaPlayer.release()
            abandonAudioFocus(audioManager, overrideSilent)
            rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                soundAsset, overrideSilent)
            if (wakeLock.isHeld) wakeLock.release()
            pendingResult.finish()
        } catch (e: Exception) {
            Log.e(TAG, "Exception during MediaPlayer for id=$alarmId: ${e.message}")
            mediaPlayer.release()
            abandonAudioFocus(audioManager, overrideSilent)
            rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes,
                soundAsset, overrideSilent)
            if (wakeLock.isHeld) wakeLock.release()
            pendingResult.finish()
        }
    }

    /**
     * Request audio focus for the Salah sound playback.
     * Uses AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK so other audio (e.g., music)
     * ducks rather than stops, and our sound is guaranteed to be heard.
     */
    private fun requestAudioFocus(audioManager: AudioManager, overrideSilent: Boolean): Int {
        // Match the MediaPlayer's audio attributes: USAGE_ALARM when overrideSilent,
        // USAGE_NOTIFICATION_RINGTONE otherwise. Bypasses background focus limits on USAGE_MEDIA.
        val usage = if (overrideSilent) {
            AudioAttributes.USAGE_ALARM
        } else {
            AudioAttributes.USAGE_NOTIFICATION_RINGTONE
        }
        val streamType = if (overrideSilent) {
            AudioManager.STREAM_ALARM
        } else {
            AudioManager.STREAM_RING
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setOnAudioFocusChangeListener { focusChange ->
                    Log.d(TAG, "Audio focus change: $focusChange")
                }
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(usage)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .build()
            audioManager.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                { focusChange -> Log.d(TAG, "Audio focus change (legacy): $focusChange") },
                streamType,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            )
        }
    }

    /**
     * Abandon audio focus after playback completes or fails.
     */
    private fun abandonAudioFocus(audioManager: AudioManager, overrideSilent: Boolean) {
        // Match the requestAudioFocus attributes for proper abandonment.
        val usage = if (overrideSilent) {
            AudioAttributes.USAGE_ALARM
        } else {
            AudioAttributes.USAGE_NOTIFICATION_RINGTONE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(usage)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .build()
            audioManager.abandonAudioFocusRequest(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
        Log.d(TAG, "Audio focus abandoned (overrideSilent=$overrideSilent)")
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

        Log.d(TAG, "Rescheduling alarm id=$alarmId for nextFireTime=$nextFireTime "
            + "(+${(nextFireTime - now) / 1000}s from now)")

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
                Log.d(TAG, "Rescheduled id=$alarmId with setAndAllowWhileIdle (inexact)")
                return
            }
        }

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            nextFireTime,
            pendingIntent
        )
        Log.d(TAG, "Rescheduled id=$alarmId with setExactAndAllowWhileIdle")
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
                Log.d(TAG, "Cancelled alarm requestCode=$requestCode for id=$alarmId")
            }
        }
    }
}