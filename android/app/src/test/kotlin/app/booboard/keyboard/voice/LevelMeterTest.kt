// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LevelMeterTest {
    @Test
    fun silenceIsZeroAndFullScaleIsOne() {
        assertEquals(0f, LevelMeter.levelFromRms(0.0), 0f)
        assertEquals(0f, LevelMeter.levelFromRms(0.000_1), 0f)
        assertEquals(1f, LevelMeter.levelFromRms(1.0), 0f)
    }

    @Test
    fun levelRisesWithLoudness() {
        val quiet = LevelMeter.levelFromRms(0.001)
        val normal = LevelMeter.levelFromRms(0.03)
        val loud = LevelMeter.levelFromRms(0.3)
        assertTrue(quiet < normal && normal < loud)
    }

    @Test
    fun feedEmitsOncePerFullBlock() {
        val meter = LevelMeter(blockSamples = 800)
        val emitted = mutableListOf<Float>()
        meter.feed(ShortArray(1600) { 4000 }, 1600) { emitted.add(it) }
        assertEquals(2, emitted.size)
        // A partial block carries over: 1000 samples complete one more block (200 are kept).
        meter.feed(ShortArray(1000) { 4000 }, 1000) { emitted.add(it) }
        assertEquals(3, emitted.size)
    }

    @Test
    fun levelFallsBackDownAfterSpeechEnds() {
        val meter = LevelMeter(blockSamples = 800)
        val levels = mutableListOf<Float>()
        meter.feed(ShortArray(8000) { 12000 }, 8000) { levels.add(it) }
        meter.feed(ShortArray(8000) { 0 }, 8000) { levels.add(it) }
        assertTrue(levels.last() < levels[9])
        assertTrue(levels.last() < 0.2f)
    }
}
