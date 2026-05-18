package com.diyaa.diyaa

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.PowerManager
import java.io.IOException

/**
 * BroadcastReceiver that plays the Salah 'ala Al-Nabi sound via MediaPlayer
 * when a native AlarmManager alarm fires.
 *
 * This is a fallback for the unreliable notification channel sound mechanism.
 * On Android 8+ (API 26+), notification channel sound configuration cannot be
 * changed after creation, and the channel sound may not play correctly when:
 * - The app process is dead (BroadcastReceiver context)
 * - The device is in Doze mode
 * - The audioAttributesUsage on the channel doesn't match the notification
 *
 * This receiver plays the sound directly via MediaPlayer, which works reliably
 * in all these scenarios because it doesn't depend on the notification system.
 */
class SalahSoundReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val soundAsset = intent.getStringExtra("soundAsset") ?: return
        val overrideSilent = intent.getBooleanExtra("overrideSilent", false)
        val alarmId = intent.getIntExtra("id", 0)

        // Acquire a WakeLock to ensure the device stays awake during sound playback.
        // This is critical because the device may be in Doze/sleep mode when the
        // alarm fires, and without a WakeLock the CPU could suspend before the
        // sound finishes playing.
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "diyaa:SalahSoundWakeLock:$alarmId"
        )
        wakeLock.acquire(30_000L) // Max 30 seconds for sound playback

        // Play the sound via MediaPlayer
        val mediaPlayer = MediaPlayer()
        try {
            // Set audio attributes based on overrideSilent:
            // - USAGE_ALARM: bypasses DND/silent mode (for overrideSilent=true)
            // - USAGE_NOTIFICATION: normal notification sound (for overrideSilent=false)
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(
                    if (overrideSilent) AudioAttributes.USAGE_ALARM
                    else AudioAttributes.USAGE_NOTIFICATION
                )
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            mediaPlayer.setAudioAttributes(audioAttributes)

            // Sound files are in res/raw/ directory. The soundAsset parameter
            // is the resource name without extension (e.g., "salah_nabi" or
            // "salah_enhanced"), which maps to res/raw/salah_nabi.mp3 and
            // res/raw/salah_enhanced.mp3 respectively.
            val resourceId = context.resources.getIdentifier(
                soundAsset, "raw", context.packageName
            )
            if (resourceId != 0) {
                val afd = context.resources.openRawResourceFd(resourceId)
                mediaPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                mediaPlayer.setOnCompletionListener {
                    it.release()
                    if (wakeLock.isHeld) wakeLock.release()
                }
                mediaPlayer.setOnErrorListener { mp, _, _ ->
                    mp.release()
                    if (wakeLock.isHeld) wakeLock.release()
                    true
                }
                mediaPlayer.prepare()
                mediaPlayer.start()
            } else {
                // Resource not found — release everything
                mediaPlayer.release()
                if (wakeLock.isHeld) wakeLock.release()
            }
        } catch (e: IOException) {
            mediaPlayer.release()
            if (wakeLock.isHeld) wakeLock.release()
        } catch (e: Exception) {
            mediaPlayer.release()
            if (wakeLock.isHeld) wakeLock.release()
        }
    }
}