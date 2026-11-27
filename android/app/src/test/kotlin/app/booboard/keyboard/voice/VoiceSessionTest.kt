// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import app.booboard.keyboard.bridge.VoiceEventKind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VoiceSessionTest {
    private val main = InlineMainThread()

    private fun run(
        mic: Microphone,
        engine: SpeechEngine,
        log: EventLog,
        limits: VoiceLimits = VoiceLimits(),
        clock: Clock = StepClock(1),
        onEnded: () -> Unit = {},
    ): VoiceSession = VoiceSession(
        mic = mic,
        engine = engine,
        main = main,
        emit = { log.emit(it) },
        clock = clock,
        onEnded = onEnded,
        limits = limits,
    )

    private fun waitUntil(timeoutMs: Long = 10_000, condition: () -> Boolean) {
        val end = System.currentTimeMillis() + timeoutMs
        while (!condition()) {
            if (System.currentTimeMillis() > end) throw AssertionError("timed out")
            Thread.sleep(2)
        }
    }

    @Test
    fun speechThenStopDeliversOneFinalAndOneStopped() {
        val log = EventLog()
        val engine = FakeEngine(speechChunks = 3, text = "  hello world  ")
        val session = run(FakeMicrophone(frames(8)), engine, log)
        session.start()
        waitUntil { engine.accepted.get() == 8 }
        session.requestStop()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertEquals(listOf("hello world"), log.finals())
        assertEquals(1, log.stoppedTimes)
        assertEquals(VoiceEventKind.STOPPED, log.events.last().kind)
        assertTrue(log.kinds().contains(VoiceEventKind.LEVEL))
        assertFalse(engine.released)
    }

    @Test
    fun stopFlushesTheUtteranceThatWasStillOpen() {
        val log = EventLog()
        // Speech never ends on its own: stop() must close the open utterance and decode it.
        val engine = FakeEngine(speechChunks = 100, text = "open words")
        val session = run(FakeMicrophone(frames(4)), engine, log)
        session.start()
        waitUntil { engine.accepted.get() == 4 }
        session.requestStop()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertEquals(listOf("open words"), log.finals())
        assertEquals(VoiceEventKind.STOPPED, log.events.last().kind)
    }

    @Test
    fun cancelDropsPendingTextAndStops() {
        val log = EventLog()
        val engine = FakeEngine(speechChunks = 100, text = "never shown")
        val session = run(FakeMicrophone(frames(4)), engine, log)
        session.start()
        waitUntil { engine.accepted.get() == 4 }
        session.requestCancel()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertTrue(log.finals().isEmpty())
        assertEquals(1, log.stoppedTimes)
    }

    @Test
    fun silenceTimeoutStopsTheSessionByItself() {
        val log = EventLog()
        val engine = FakeEngine(speechChunks = 0)
        // Two silent chunks (3200 samples) reach the limit.
        val limits = VoiceLimits(silenceLimitSamples = 3_200)
        val session = run(FakeMicrophone(frames(10)), engine, log, limits)
        session.start()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertTrue(log.finals().isEmpty())
        assertEquals(1, log.stoppedTimes)
    }

    @Test
    fun partialsAreEmittedWhileSpeaking() {
        val log = EventLog()
        val engine = FakeEngine(speechChunks = 1_000, text = "partial text")
        // Each clock read advances 10 ms, so a decode always fits in the 700 ms budget.
        val session = run(FakeMicrophone(frames(60)), engine, log, clock = StepClock(10))
        session.start()
        waitUntil { engine.accepted.get() == 60 }
        session.requestStop()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertTrue(log.partials().isNotEmpty())
        assertEquals("partial text", log.partials().first())
        assertTrue(log.finals().isNotEmpty())
        assertEquals(1, log.stoppedTimes)
    }

    @Test
    fun slowPartialDecodesAreSkipped() {
        val log = EventLog()
        // Every decode really takes 800 ms (wall clock), longer than the 700 ms budget: no partial.
        val engine = FakeEngine(speechChunks = 1_000, text = "slow", decodeDelayMs = 800)
        val wall = Clock { System.currentTimeMillis() }
        val session = run(FakeMicrophone(frames(12)), engine, log, clock = wall)
        session.start()
        waitUntil { engine.accepted.get() == 12 }
        session.requestStop()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertTrue(log.partials().isEmpty())
    }

    @Test
    fun micBusyReportsAudioBusyThenStopped() {
        val log = EventLog()
        val session = run(FakeMicrophone(emptyList(), failWith = "audio_busy"), FakeEngine(), log)
        session.start()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertEquals(listOf("audio_busy"), log.errors())
        assertEquals(VoiceEventKind.STOPPED, log.events.last().kind)
        assertEquals(1, log.stoppedTimes)
    }

    @Test
    fun decoderFailureReportsModelFailedThenStops() {
        val log = EventLog()
        val mic = FakeMicrophone(frames(3))
        val session = run(mic, FakeEngine(speechChunks = 10, failOnAccept = true), log)
        session.start()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertEquals(listOf("model_failed"), log.errors())
        assertEquals(1, log.stoppedTimes)
        // The capture thread must end too, releasing the microphone.
        waitUntil { mic.stopped }
    }

    @Test
    fun levelEventsComeTwentyTimesASecond() {
        val log = EventLog()
        // 10 reads of 1600 samples = 100 ms each, so 2 level blocks per read: 20 events.
        val engine = FakeEngine(speechChunks = 0)
        val session = run(FakeMicrophone(frames(10)), engine, log)
        session.start()
        waitUntil { engine.accepted.get() == 10 }
        session.requestStop()
        assertTrue(log.awaitStopped())
        Thread.sleep(20)

        assertEquals(20, log.events.count { it.kind == VoiceEventKind.LEVEL })
        assertFalse(log.events.any { it.kind == VoiceEventKind.ERROR })
    }

    @Test
    fun finalTextIsDecodedWithAudioAroundTheUtterance() {
        val log = EventLog()
        // Speech in chunks 0-2 (4800 samples); the detector reports it when chunk 3 arrives.
        val engine = FakeEngine(speechChunks = 3, text = "padded")
        val session = run(FakeMicrophone(frames(8)), engine, log)
        session.start()
        waitUntil { engine.accepted.get() == 8 }
        session.requestStop()
        assertTrue(log.awaitStopped())

        assertEquals(listOf("padded"), log.finals())
        // Nothing before the start of the session; after it, the post-roll reaches into chunk 3 (6400).
        assertTrue(engine.decodedSizes.toString(), engine.decodedSizes.contains(6_400))
    }

    @Test
    fun audioHistoryKeepsTheNewestSamplesAndRefusesLostStarts() {
        val h = AudioHistory(10)
        h.append(FloatArray(8) { it.toFloat() })
        assertEquals(listOf(0f, 1f, 2f, 3f, 4f, 5f, 6f), h.slice(-3, 7, 2)!!.toList())
        h.append(FloatArray(6) { (8 + it).toFloat() })
        // 14 samples written, the oldest kept is 4.
        assertEquals(null, h.slice(0, 6, 3))
        assertEquals(listOf(4f, 5f, 6f, 7f, 8f), h.slice(0, 9, 4)!!.toList())
        assertEquals(listOf(12f, 13f), h.slice(12, 40, 12)!!.toList())
        assertEquals(null, h.slice(14, 20, 14))
        h.clear()
        assertEquals(0L, h.total)
    }
}
