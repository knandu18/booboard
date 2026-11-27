// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.ime

import app.booboard.keyboard.bridge.HapticKind
import kotlin.math.abs
import kotlin.math.roundToInt

/** What to do for one haptic request. Pure data so the mapping can be unit-tested on the JVM. */
internal sealed interface HapticPlan {
    /** Strength is zero: stay silent. */
    data object None : HapticPlan

    /** Let the system decide: `View.performHapticFeedback`, which respects the user's touch-feedback setting. */
    data class ViewHaptic(val kind: HapticKind) : HapticPlan

    /** `VibrationEffect.createPredefined` (API 29+). */
    data class Predefined(val effect: PredefinedEffect) : HapticPlan

    /** `VibrationEffect.createOneShot`; [amplitude] is 1..255, or -1 for the device default. */
    data class OneShot(val millis: Long, val amplitude: Int) : HapticPlan

    /** `VibrationEffect.createWaveform`; [amplitudes] is null on hardware without amplitude control. */
    class Waveform(val timings: LongArray, val amplitudes: IntArray?) : HapticPlan
}

internal enum class PredefinedEffect { TICK, CLICK, HEAVY_CLICK }

internal object HapticPlanner {
    /** The strength slider's default: this value means "use the system's own keyboard-tap feedback". */
    const val DEFAULT_STRENGTH = 0.5
    private const val DEFAULT_TOLERANCE = 0.03
    private const val OFF_BELOW = 0.02

    /**
     * @param strength the 0..1 slider value
     * @param hasAmplitudeControl `Vibrator.hasAmplitudeControl()`
     * @param sdk `Build.VERSION.SDK_INT`
     */
    fun plan(kind: HapticKind, strength: Double, hasAmplitudeControl: Boolean, sdk: Int): HapticPlan {
        val s = if (strength.isNaN()) DEFAULT_STRENGTH else strength.coerceIn(0.0, 1.0)
        if (s < OFF_BELOW) return HapticPlan.None

        // Below API 30 the system has no "reject" effect: fall through to the custom double pulse.
        val systemCanDoIt = !(kind == HapticKind.ERROR && sdk < 30)
        if (abs(s - DEFAULT_STRENGTH) <= DEFAULT_TOLERANCE && systemCanDoIt) return HapticPlan.ViewHaptic(kind)

        // 0.5 on the slider is "normal" (intensity 1.0); 1.0 is twice as strong.
        val intensity = s * 2.0 * scale(kind)
        val amplitude = (intensity * 128).roundToInt().coerceIn(1, 255)

        if (kind == HapticKind.ERROR) {
            // Double pulse: buzz, gap, buzz.
            val timings = longArrayOf(0, 18, 45, 28)
            return HapticPlan.Waveform(timings, if (hasAmplitudeControl) intArrayOf(0, amplitude, 0, amplitude) else null)
        }
        if (hasAmplitudeControl) return HapticPlan.OneShot(duration(kind), amplitude)
        if (sdk >= 29) {
            val effect = when {
                intensity < 0.9 -> PredefinedEffect.TICK
                intensity < 1.7 -> PredefinedEffect.CLICK
                else -> PredefinedEffect.HEAVY_CLICK
            }
            return HapticPlan.Predefined(effect)
        }
        // Old devices cannot vary strength: vary the length instead.
        return HapticPlan.OneShot((duration(kind) * intensity).toLong().coerceIn(5, 60), -1)
    }

    /** Relative strength of each kind: repeat ticks are lighter, long presses firmer. */
    fun scale(kind: HapticKind): Double = when (kind) {
        HapticKind.REPEAT_TICK -> 0.55
        HapticKind.GESTURE_START -> 0.8
        HapticKind.KEY_TAP, HapticKind.GESTURE_COMMIT, HapticKind.TOGGLE -> 1.0
        HapticKind.ERROR -> 1.3
        HapticKind.KEY_LONG_PRESS -> 1.5
    }

    private fun duration(kind: HapticKind): Long = when (kind) {
        HapticKind.REPEAT_TICK -> 8
        HapticKind.GESTURE_START -> 12
        HapticKind.KEY_TAP -> 14
        HapticKind.TOGGLE -> 16
        HapticKind.GESTURE_COMMIT -> 18
        HapticKind.ERROR -> 20
        HapticKind.KEY_LONG_PRESS -> 24
    }
}
