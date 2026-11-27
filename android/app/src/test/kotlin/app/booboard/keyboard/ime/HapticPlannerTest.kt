// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.ime

import app.booboard.keyboard.bridge.HapticKind
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class HapticPlannerTest {
    private fun plan(kind: HapticKind, strength: Double, amp: Boolean = true, sdk: Int = 34) =
        HapticPlanner.plan(kind, strength, amp, sdk)

    @Test
    fun zeroStrengthIsSilent() {
        for (k in HapticKind.entries) assertEquals(HapticPlan.None, plan(k, 0.0))
    }

    @Test
    fun defaultStrengthUsesTheSystemSetting() {
        for (k in HapticKind.entries) {
            if (k == HapticKind.ERROR) continue
            assertEquals(HapticPlan.ViewHaptic(k), plan(k, 0.5))
            assertEquals(HapticPlan.ViewHaptic(k), plan(k, 0.52, amp = false))
        }
        assertEquals(HapticPlan.ViewHaptic(HapticKind.ERROR), plan(HapticKind.ERROR, 0.5, sdk = 30))
    }

    @Test
    fun errorOnOldAndroidIsADoublePulseEvenAtDefaultStrength() {
        val p = plan(HapticKind.ERROR, 0.5, sdk = 28) as HapticPlan.Waveform
        assertArrayEquals(longArrayOf(0, 18, 45, 28), p.timings)
        assertEquals(4, p.amplitudes!!.size)
    }

    @Test
    fun amplitudeScalesWithStrength() {
        val soft = plan(HapticKind.KEY_TAP, 0.2) as HapticPlan.OneShot
        val strong = plan(HapticKind.KEY_TAP, 1.0) as HapticPlan.OneShot
        assertTrue(soft.amplitude < strong.amplitude)
        assertEquals(255, strong.amplitude)
        assertTrue(soft.amplitude in 1..255)
    }

    @Test
    fun repeatTicksAreLighterAndLongPressesStrongerThanTaps() {
        val tap = plan(HapticKind.KEY_TAP, 0.8) as HapticPlan.OneShot
        val tick = plan(HapticKind.REPEAT_TICK, 0.8) as HapticPlan.OneShot
        val long = plan(HapticKind.KEY_LONG_PRESS, 0.8) as HapticPlan.OneShot
        assertTrue(tick.amplitude < tap.amplitude)
        assertTrue(long.amplitude > tap.amplitude)
        assertTrue(tick.millis < tap.millis)
    }

    @Test
    fun errorIsADoublePulseWithAmplitudeWhenAvailable() {
        val p = plan(HapticKind.ERROR, 0.9) as HapticPlan.Waveform
        assertEquals(4, p.timings.size)
        assertEquals(0, p.amplitudes!![0])
        assertEquals(0, p.amplitudes[2])
        assertTrue(p.amplitudes[1] > 0)
        assertNull((plan(HapticKind.ERROR, 0.9, amp = false) as HapticPlan.Waveform).amplitudes)
    }

    @Test
    fun withoutAmplitudeControlPredefinedEffectsAreUsed() {
        assertEquals(HapticPlan.Predefined(PredefinedEffect.TICK), plan(HapticKind.KEY_TAP, 0.2, amp = false))
        assertEquals(HapticPlan.Predefined(PredefinedEffect.CLICK), plan(HapticKind.KEY_TAP, 0.7, amp = false))
        assertEquals(HapticPlan.Predefined(PredefinedEffect.HEAVY_CLICK), plan(HapticKind.KEY_TAP, 1.0, amp = false))
        assertEquals(HapticPlan.Predefined(PredefinedEffect.TICK), plan(HapticKind.REPEAT_TICK, 0.6, amp = false))
    }

    @Test
    fun veryOldDevicesVaryDurationInstead() {
        val soft = plan(HapticKind.KEY_TAP, 0.2, amp = false, sdk = 26) as HapticPlan.OneShot
        val strong = plan(HapticKind.KEY_TAP, 1.0, amp = false, sdk = 26) as HapticPlan.OneShot
        assertEquals(-1, soft.amplitude)
        assertTrue(soft.millis < strong.millis)
        assertTrue(soft.millis >= 5 && strong.millis <= 60)
    }

    @Test
    fun outOfRangeAndNanStrengthsAreSafe() {
        assertEquals(HapticPlan.ViewHaptic(HapticKind.KEY_TAP), plan(HapticKind.KEY_TAP, Double.NaN))
        assertEquals(255, (plan(HapticKind.KEY_TAP, 7.0) as HapticPlan.OneShot).amplitude)
        assertEquals(HapticPlan.None, plan(HapticKind.KEY_TAP, -3.0))
    }
}
