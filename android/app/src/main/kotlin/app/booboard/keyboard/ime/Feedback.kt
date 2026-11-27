// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.ime

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.HapticFeedbackConstants
import android.view.View
import app.booboard.keyboard.bridge.FeedbackConfigMessage
import app.booboard.keyboard.bridge.HapticKind
import app.booboard.keyboard.bridge.KeySoundKind

/** Key haptics and click sounds. Everything is best-effort: feedback must never break typing. */
internal class Feedback(private val context: Context) {

    private var config = FeedbackConfigMessage(
        hapticsEnabled = false, // off by default, like FeedbackSettings in Dart
        hapticStrength = HapticPlanner.DEFAULT_STRENGTH,
        soundsEnabled = false,
        soundVolume = -1.0,
    )
    private val audio by lazy { context.getSystemService(Context.AUDIO_SERVICE) as AudioManager }
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= 31) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    fun configure(newConfig: FeedbackConfigMessage) {
        config = newConfig
    }

    fun haptic(kind: HapticKind, view: View?) {
        if (!config.hapticsEnabled) return
        try {
            val vib = vibrator
            val plan = HapticPlanner.plan(
                kind,
                config.hapticStrength,
                hasAmplitudeControl = vib != null && Build.VERSION.SDK_INT >= 26 && vib.hasAmplitudeControl(),
                sdk = Build.VERSION.SDK_INT,
            )
            when (plan) {
                HapticPlan.None -> Unit
                is HapticPlan.ViewHaptic -> view?.performHapticFeedback(systemConstant(plan.kind))
                is HapticPlan.Predefined -> vibrate(vib, predefined(plan.effect))
                is HapticPlan.OneShot -> vibrate(
                    vib,
                    VibrationEffect.createOneShot(
                        plan.millis,
                        if (plan.amplitude < 0) VibrationEffect.DEFAULT_AMPLITUDE else plan.amplitude,
                    ),
                )
                is HapticPlan.Waveform -> vibrate(
                    vib,
                    plan.amplitudes?.let { VibrationEffect.createWaveform(plan.timings, it, -1) }
                        ?: VibrationEffect.createWaveform(plan.timings, -1),
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "haptic failed: ${e.javaClass.simpleName}")
        }
    }

    /** Like AOSP LatinIME: key sounds only while the ringer is in normal mode (not silent or vibrate). */
    fun sound(kind: KeySoundKind) {
        if (!config.soundsEnabled) return
        try {
            if (audio.ringerMode != AudioManager.RINGER_MODE_NORMAL) return
            val effect = when (kind) {
                KeySoundKind.SPACE -> AudioManager.FX_KEYPRESS_SPACEBAR
                KeySoundKind.DELETE -> AudioManager.FX_KEYPRESS_DELETE
                KeySoundKind.ENTER -> AudioManager.FX_KEYPRESS_RETURN
                KeySoundKind.STANDARD -> AudioManager.FX_KEYPRESS_STANDARD
            }
            val volume = config.soundVolume
            if (volume < 0) audio.playSoundEffect(effect) else audio.playSoundEffect(effect, volume.toFloat().coerceIn(0f, 1f))
        } catch (e: Exception) {
            Log.w(TAG, "sound failed: ${e.javaClass.simpleName}")
        }
    }

    private fun vibrate(vib: Vibrator?, effect: VibrationEffect) {
        if (vib == null || !vib.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= 33) {
            vib.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH))
        } else {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            @Suppress("DEPRECATION")
            vib.vibrate(effect, attrs)
        }
    }

    private fun predefined(effect: PredefinedEffect): VibrationEffect {
        // Only reached on API 29+ (the planner never asks for these earlier).
        val id = when (effect) {
            PredefinedEffect.TICK -> VibrationEffect.EFFECT_TICK
            PredefinedEffect.CLICK -> VibrationEffect.EFFECT_CLICK
            PredefinedEffect.HEAVY_CLICK -> VibrationEffect.EFFECT_HEAVY_CLICK
        }
        return VibrationEffect.createPredefined(id)
    }

    private fun systemConstant(kind: HapticKind): Int = when (kind) {
        HapticKind.KEY_TAP -> HapticFeedbackConstants.KEYBOARD_TAP
        HapticKind.KEY_LONG_PRESS -> HapticFeedbackConstants.LONG_PRESS
        HapticKind.REPEAT_TICK ->
            if (Build.VERSION.SDK_INT >= 27) HapticFeedbackConstants.TEXT_HANDLE_MOVE else HapticFeedbackConstants.CLOCK_TICK
        HapticKind.GESTURE_START ->
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.GESTURE_START else HapticFeedbackConstants.KEYBOARD_TAP
        HapticKind.GESTURE_COMMIT ->
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.GESTURE_END else HapticFeedbackConstants.KEYBOARD_TAP
        HapticKind.TOGGLE ->
            if (Build.VERSION.SDK_INT >= 34) HapticFeedbackConstants.TOGGLE_ON else HapticFeedbackConstants.KEYBOARD_TAP
        HapticKind.ERROR ->
            if (Build.VERSION.SDK_INT >= 30) HapticFeedbackConstants.REJECT else HapticFeedbackConstants.LONG_PRESS
    }

    private companion object {
        const val TAG = "BooBoardFeedback"
    }
}
