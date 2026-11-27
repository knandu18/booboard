// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import app.booboard.keyboard.bridge.VoiceEventKind
import app.booboard.keyboard.bridge.VoiceEventMessage
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/** Test doubles for the voice pipeline. No Android classes. OWNER: Wave 3-D. */

/** Runs posted work inline on the calling thread. Delayed work is recorded, not run. */
class InlineMainThread : MainThread {
    val delayed = ConcurrentLinkedQueue<Pair<Long, () -> Unit>>()

    override fun post(block: () -> Unit) = block()

    override fun postDelayed(delayMs: Long, block: () -> Unit) {
        delayed.add(delayMs to block)
    }
}

/** Collects events; [stoppedLatch] opens on the first `stopped`. */
class EventLog {
    val events = ConcurrentLinkedQueue<VoiceEventMessage>()
    val stoppedLatch = CountDownLatch(1)
    private val stoppedCount = AtomicInteger(0)

    fun emit(event: VoiceEventMessage) {
        events.add(event)
        if (event.kind == VoiceEventKind.STOPPED) {
            stoppedCount.incrementAndGet()
            stoppedLatch.countDown()
        }
    }

    val stoppedTimes: Int get() = stoppedCount.get()

    fun kinds(): List<VoiceEventKind> = events.map { it.kind }

    fun finals(): List<String> = events.filter { it.kind == VoiceEventKind.FINAL_TEXT }.mapNotNull { it.text }

    fun partials(): List<String> = events.filter { it.kind == VoiceEventKind.PARTIAL }.mapNotNull { it.text }

    fun errors(): List<String> = events.filter { it.kind == VoiceEventKind.ERROR }.mapNotNull { it.errorCode }

    fun awaitStopped(): Boolean = stoppedLatch.await(10, TimeUnit.SECONDS)
}

/** Plays [frames] (one per read), then returns silence-sized empty reads until stopped. */
class FakeMicrophone(
    private val frames: List<ShortArray>,
    private val startOk: Boolean = true,
    private val failWith: String? = null,
) : Microphone {
    @Volatile
    var stopped = false
        private set
    private val next = AtomicInteger(0)

    override fun start(): Boolean = startOk

    override fun read(buffer: ShortArray): Int {
        if (failWith != null) throw VoiceFailure(failWith)
        val i = next.getAndIncrement()
        if (i >= frames.size) {
            Thread.sleep(1)
            return 0
        }
        val frame = frames[i]
        System.arraycopy(frame, 0, buffer, 0, frame.size)
        return frame.size
    }

    override fun stop() {
        stopped = true
    }
}

/**
 * Speech for the first [speechChunks] accepted chunks, then silence. When speech ends, one segment (all the
 * speech samples) is ready. [decode] returns [text]. Counts calls for assertions.
 */
internal class FakeEngine(
    private val speechChunks: Int = 0,
    private val text: String = "hello world",
    private val failOnAccept: Boolean = false,
    private val decodeDelayMs: Long = 0,
) : SpeechEngine {
    val accepted = AtomicInteger(0)
    val decodes = AtomicInteger(0)
    val decodedSizes = ConcurrentLinkedQueue<Int>()
    private var speechSamples = 0
    private var segmentReady = false
    @Volatile
    var released = false
        private set

    override fun decode(samples: FloatArray): String {
        decodes.incrementAndGet()
        decodedSizes.add(samples.size)
        if (decodeDelayMs > 0) Thread.sleep(decodeDelayMs)
        return text
    }

    override fun acceptAudio(samples: FloatArray) {
        if (failOnAccept) throw IllegalStateException("boom")
        val n = accepted.incrementAndGet()
        if (n <= speechChunks) {
            speechSamples += samples.size
        } else if (n == speechChunks + 1 && speechSamples > 0) {
            segmentReady = true
        }
    }

    override fun isSpeaking(): Boolean = accepted.get() <= speechChunks

    @Synchronized
    override fun nextSegment(): VoiceSegment? {
        if (!segmentReady) return null
        segmentReady = false
        val size = speechSamples
        speechSamples = 0
        return VoiceSegment(0, FloatArray(size) { 0.5f })
    }

    override fun flushAudio() {
        if (speechSamples > 0) segmentReady = true
    }

    override fun resetAudio() = Unit

    override fun release() {
        released = true
    }
}

/** A clock the test advances: each read moves time by [stepMs]. */
class StepClock(private val stepMs: Long) : Clock {
    private val now = AtomicLong(0)

    override fun nowMs(): Long = now.addAndGet(stepMs)
}

/** Builds [count] frames of 1600 PCM16 samples, all at [amplitude]. */
fun frames(count: Int, amplitude: Int = 1000): List<ShortArray> =
    List(count) { ShortArray(1600) { amplitude.toShort() } }
