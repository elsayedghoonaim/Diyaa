package com.example.diyaa_app

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
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.util.Log
import java.io.IOException

/**
 * BroadcastReceiver that plays the Salah 'ala Al-Nabi sound via MediaPlayer
 * when a native AlarmManager alarm fires, and auto-reschedules for the next
 * interval.
 */
class SalahSoundReceiver : BroadcastReceiver() {
    companion object {
        private const val PREFS_NAME = "diyaa_salah_prefs"
        private const val KEY_ENABLED = "salah_nabi_enabled"
        private const val TAG = "DiyaaSalahSound"
    }

    override fun onReceive(context: Context, intent: Intent) {
        var soundAsset = intent.getStringExtra("soundAsset") ?: return
        if (soundAsset == "salah_enhanced") {
            soundAsset = "salah_enhanced_v4"
        }
        val overrideSilent = intent.getBooleanExtra("overrideSilent", false)
        val alarmId = intent.getIntExtra("id", 0)
        val intervalMinutes = intent.getIntExtra("intervalMinutes", 0)
        val scheduledTimeMillis = intent.getLongExtra("scheduledTimeMillis", 0L)

        Log.d(TAG, "onReceive: id=$alarmId, sound=$soundAsset, overrideSilent=$overrideSilent, "
            + "interval=$intervalMinutes, scheduledTime=$scheduledTimeMillis")

        // Use goAsync() to extend the BroadcastReceiver lifecycle
        val pendingResult = goAsync()

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean(KEY_ENABLED, false)

        Log.d(TAG, "SharedPreferences salah_nabi_enabled=$isEnabled (default=false)")
        Log.d(TAG, "SharedPreferences ALL: ${prefs.all}")

        if (!isEnabled) {
            Log.w(TAG, "salah_nabi_enabled=false → CANCELING alarm id=$alarmId.")
            cancelAlarmById(context, alarmId)
            pendingResult.finish()
            return
        }

        // Acquire a WakeLock
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "diyaa:SalahSoundWakeLock:$alarmId"
        )
        wakeLock.acquire(30_000L) // Max 30 seconds for sound playback + reschedule
        Log.d(TAG, "WakeLock acquired for id=$alarmId")

        // Show visual notification skipped as per user request
        showVisualNotification(context, alarmId, soundAsset, overrideSilent)

        // Request audio focus before playing
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val focusRequest = requestAudioFocus(audioManager, overrideSilent)

        // If overrideSilent is enabled, ensure the alarm volume is unmuted
        var originalAlarmVolume = -1
        if (overrideSilent) {
            try {
                originalAlarmVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    audioManager.adjustStreamVolume(AudioManager.STREAM_ALARM, AudioManager.ADJUST_UNMUTE, 0)
                }
                val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                val targetVol = (maxVol * 0.6).toInt().coerceAtLeast(1)
                if (originalAlarmVolume < targetVol) {
                    audioManager.setStreamVolume(AudioManager.STREAM_ALARM, targetVol, 0)
                    Log.d(TAG, "overrideSilent=true. STREAM_ALARM volume ($originalAlarmVolume) is below target ($targetVol). Temporarily raised to $targetVol (max: $maxVol)")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to temporarily adjust STREAM_ALARM volume: ${e.message}")
            }
        }

        val usage = if (overrideSilent) {
            AudioAttributes.USAGE_ALARM
        } else {
            AudioAttributes.USAGE_NOTIFICATION_RINGTONE
        }
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(usage)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val resourceId = context.resources.getIdentifier(
            soundAsset, "raw", context.packageName
        )

        if (resourceId == 0) {
            Log.e(TAG, "Resource NOT found: $soundAsset → resourceId=0. Package: ${context.packageName}")
            abandonAudioFocus(audioManager, focusRequest)
            restoreAlarmVolume(audioManager, originalAlarmVolume)
            rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes, soundAsset, overrideSilent)
            if (wakeLock.isHeld) wakeLock.release()
            pendingResult.finish()
            return
        }

        Log.d(TAG, "Resource found: $soundAsset → resourceId=$resourceId")

        val mediaPlayer = try {
            val uri = Uri.parse("android.resource://${context.packageName}/$resourceId")
            Log.d(TAG, "Creating MediaPlayer with URI: $uri")

            val mp = MediaPlayer()
            mp.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
            mp.setAudioAttributes(audioAttributes)
            mp.setDataSource(context, uri)
            mp.setVolume(1.0f, 1.0f)
            mp.prepare()
            Log.d(TAG, "MediaPlayer prepared synchronously. Duration: ${mp.duration}ms")
            mp
        } catch (e: Exception) {
            Log.e(TAG, "MediaPlayer creation/prepare FAILED for $soundAsset (id=$alarmId): ${e.message}", e)
            null
        }

        if (mediaPlayer != null) {
            mediaPlayer.setOnCompletionListener { mp ->
                Log.d(TAG, "MediaPlayer completed for id=$alarmId")
                mp.release()
                abandonAudioFocus(audioManager, focusRequest)
                restoreAlarmVolume(audioManager, originalAlarmVolume)
                rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes, soundAsset, overrideSilent)
                if (wakeLock.isHeld) wakeLock.release()
                pendingResult.finish()
            }
            mediaPlayer.setOnErrorListener { mp, what, extra ->
                Log.e(TAG, "MediaPlayer error during playback for id=$alarmId: what=$what, extra=$extra")
                mp.release()
                abandonAudioFocus(audioManager, focusRequest)
                restoreAlarmVolume(audioManager, originalAlarmVolume)
                rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes, soundAsset, overrideSilent)
                if (wakeLock.isHeld) wakeLock.release()
                pendingResult.finish()
                true
            }

            try {
                mediaPlayer.start()
                Log.d(TAG, "MediaPlayer started successfully for id=$alarmId, sound=$soundAsset, duration=${mediaPlayer.duration}ms")
            } catch (e: Exception) {
                Log.e(TAG, "MediaPlayer.start() FAILED for id=$alarmId: ${e.message}", e)
                mediaPlayer.release()
                playRingtoneFallback(context, resourceId, audioAttributes, audioManager,
                    focusRequest, originalAlarmVolume, alarmId, scheduledTimeMillis,
                    intervalMinutes, soundAsset, overrideSilent, wakeLock, pendingResult)
            }
        } else {
            Log.w(TAG, "MediaPlayer unavailable, falling back to Ringtone API for id=$alarmId")
            playRingtoneFallback(context, resourceId, audioAttributes, audioManager,
                focusRequest, originalAlarmVolume, alarmId, scheduledTimeMillis,
                intervalMinutes, soundAsset, overrideSilent, wakeLock, pendingResult)
        }
    }

    private fun playRingtoneFallback(
        context: Context,
        resourceId: Int,
        audioAttributes: AudioAttributes,
        audioManager: AudioManager,
        focusRequest: Any?,
        originalAlarmVolume: Int,
        alarmId: Int,
        scheduledTimeMillis: Long,
        intervalMinutes: Int,
        soundAsset: String,
        overrideSilent: Boolean,
        wakeLock: PowerManager.WakeLock,
        pendingResult: PendingResult
    ) {
        try {
            val uri = Uri.parse("android.resource://${context.packageName}/$resourceId")
            val ringtone = RingtoneManager.getRingtone(context, uri)
            if (ringtone != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    ringtone.audioAttributes = audioAttributes
                }
                ringtone.play()
                Log.d(TAG, "Ringtone fallback playing for id=$alarmId, sound=$soundAsset")

                Thread {
                    try {
                        var waited = 0
                        while (ringtone.isPlaying && waited < 15000) {
                            Thread.sleep(200)
                            waited += 200
                        }
                        ringtone.stop()
                        Log.d(TAG, "Ringtone fallback finished for id=$alarmId (waited ${waited}ms)")
                    } catch (e: Exception) {
                        Log.e(TAG, "Ringtone wait error: ${e.message}")
                    } finally {
                        abandonAudioFocus(audioManager, focusRequest)
                        restoreAlarmVolume(audioManager, originalAlarmVolume)
                        rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes, soundAsset, overrideSilent)
                        if (wakeLock.isHeld) wakeLock.release()
                        pendingResult.finish()
                    }
                }.start()
            } else {
                Log.e(TAG, "Ringtone fallback: getRingtone returned null for id=$alarmId")
                abandonAudioFocus(audioManager, focusRequest)
                restoreAlarmVolume(audioManager, originalAlarmVolume)
                rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes, soundAsset, overrideSilent)
                if (wakeLock.isHeld) wakeLock.release()
                pendingResult.finish()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Ringtone fallback FAILED for id=$alarmId: ${e.message}", e)
            abandonAudioFocus(audioManager, focusRequest)
            restoreAlarmVolume(audioManager, originalAlarmVolume)
            rescheduleAlarm(context, alarmId, scheduledTimeMillis, intervalMinutes, soundAsset, overrideSilent)
            if (wakeLock.isHeld) wakeLock.release()
            pendingResult.finish()
        }
    }

    private fun requestAudioFocus(audioManager: AudioManager, overrideSilent: Boolean): Any? {
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
            val result = audioManager.requestAudioFocus(focusRequest)
            Log.d(TAG, "Audio focus request result: $result (AUDIOFOCUS_REQUEST_GRANTED=${AudioManager.AUDIOFOCUS_REQUEST_GRANTED})")
            focusRequest
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager.requestAudioFocus(
                { focusChange -> Log.d(TAG, "Audio focus change (legacy): $focusChange") },
                streamType,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
            )
            Log.d(TAG, "Audio focus request (legacy) result: $result (AUDIOFOCUS_REQUEST_GRANTED=${AudioManager.AUDIOFOCUS_REQUEST_GRANTED})")
            null
        }
    }

    private fun abandonAudioFocus(audioManager: AudioManager, focusRequest: Any?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (focusRequest is AudioFocusRequest) {
                val result = audioManager.abandonAudioFocusRequest(focusRequest)
                Log.d(TAG, "Audio focus abandoned via abandonAudioFocusRequest: $result")
            } else {
                Log.w(TAG, "abandonAudioFocus called on API 26+ but focusRequest is not an AudioFocusRequest: $focusRequest")
            }
        } else {
            @Suppress("DEPRECATION")
            val result = audioManager.abandonAudioFocus(null)
            Log.d(TAG, "Audio focus abandoned (legacy): $result")
        }
    }

    private fun rescheduleAlarm(
        context: Context,
        alarmId: Int,
        scheduledTimeMillis: Long,
        intervalMinutes: Int,
        soundAsset: String,
        overrideSilent: Boolean
    ) {
        if (intervalMinutes <= 0) return

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intervalMillis = intervalMinutes * 60_000L
        var nextFireTime = scheduledTimeMillis + intervalMillis

        val now = System.currentTimeMillis()
        while (nextFireTime <= now) {
            nextFireTime += intervalMillis
        }

        Log.d(TAG, "Rescheduling alarm id=$alarmId for nextFireTime=$nextFireTime (+${(nextFireTime - now) / 1000}s from now)")

        val newIntent = Intent(context, SalahSoundReceiver::class.java).apply {
            putExtra("id", alarmId)
            putExtra("soundAsset", soundAsset)
            putExtra("overrideSilent", overrideSilent)
            putExtra("intervalMinutes", intervalMinutes)
            putExtra("scheduledTimeMillis", nextFireTime)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId + 10000,
            newIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

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

    private fun restoreAlarmVolume(audioManager: AudioManager, originalVolume: Int) {
        if (originalVolume >= 0) {
            try {
                audioManager.setStreamVolume(AudioManager.STREAM_ALARM, originalVolume, 0)
                if (originalVolume == 0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    audioManager.adjustStreamVolume(AudioManager.STREAM_ALARM, AudioManager.ADJUST_MUTE, 0)
                }
                Log.d(TAG, "Restored STREAM_ALARM volume to $originalVolume")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to restore STREAM_ALARM volume: ${e.message}")
            }
        }
    }

    private fun showVisualNotification(context: Context, alarmId: Int, soundAsset: String, overrideSilent: Boolean) {
        // Visual notification disabled per user request.
        // The sound will still play natively via the MediaPlayer logic above.
        Log.d(TAG, "Visual notification skipped for id=$alarmId")
    }
}
