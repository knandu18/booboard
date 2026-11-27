// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import app.booboard.keyboard.bridge.VoiceEventKind
import app.booboard.keyboard.bridge.VoiceEventMessage
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.log10
import kotlin.math.sqrt

/**
 * One voice session: a capture thread reads the microphone, a decode thread runs voice-activity
 * detection and speech recognition, and events go to the main thread. OWNER: Wave 3-D.
 *
 * Everything here is free of Android classes so the JVM tests can drive it with fakes. Audio stays
 * in memory: every buffer is zeroed once it has been used. Recognised text is never logged.
 */

/** Speech recognition plus voice-activity detection for one loaded model. Used on the decode thread only. */
internal interface SpeechEngine {
    /** Text of one utterance (16 kHz mono samples in -1..1). */
    fun decode(samples: FloatArray): String

    /** Feeds audio to the voice-activity detector. */
    fun acceptAudio(samples: FloatArray)

    /** True while the detector hears speech. */
    fun isSpeaking(): Boolean

    /** The next finished utterance, or null when none is ready. */
    fun nextSegment(): VoiceSegment?

    /** Ends the open utterance so that [nextSegment] returns it. */
    fun flushAudio()

    /** Forgets the detector's state (new session). */
    fun resetAudio()

    fun release()
}

/**
 * One utterance from the voice-activity detector. [start] counts samples since [SpeechEngine.resetAudio],
 * so the session can cut the utterance from its own recent audio with some room before and after.
 */
internal class VoiceSegment(val start: Long, val samples: FloatArray)

/** Microphone capture. [read] blocks for about one buffer of audio. */
internal interface Microphone {
    /** Opens and starts capture. False when the microphone is busy or unavailable. */
    fun start(): Boolean

    /** Fills [buffer] with PCM16 samples and returns how many, 0 for none. Throws [VoiceFailure]. */
    fun read(buffer: ShortArray): Int

    /** Stops and frees the microphone. Safe to call twice. */
    fun stop()
}

/** Runs work on the main thread. Tests run it inline. */
internal interface MainThread {
    fun post(block: () -> Unit)

    fun postDelayed(delayMs: Long, block: () -> Unit)
}

/** Milliseconds on a monotonic clock. */
internal fun interface Clock {
    fun nowMs(): Long
}

/** An error with a pigeon error code ('audio_busy', 'model_failed', 'permission_revoked', 'internal'). */
internal class VoiceFailure(val code: String) : Exception(code)

/** Timing rules from the brief. Sample counts are at 16 kHz. */
internal data class VoiceLimits(
    val readSamples: Int = 1_600,
    val levelBlockSamples: Int = 800,
    val partialIntervalMs: Long = 700,
    val minPartialSamples: Int = 4_800,
    val maxBufferedSamples: Int = 16_000 * 30,
    val silenceLimitSamples: Long = 16_000L * 5,
    val sessionLimitSamples: Long = 16_000L * 60,
    val pollMs: Long = 50,
    /** Audio kept before and after each utterance: the detector starts late and cuts word endings. */
    val prerollSamples: Int = 6_400,
    val postrollSamples: Int = 4_800,
    /** Recent audio kept for that padding (longer than the detector's 12 s utterance cap). */
    val historySamples: Int = 16_000 * 20,
)

/**
 * Smoothed input level from RMS, 0..1 (-50 dB gives 0, -10 dB gives 1). Attack is faster than release,
 * so the shape reacts to speech and settles quietly.
 */
internal class LevelMeter(private val blockSamples: Int) {
    private var value = 0f
    private var sumSquares = 0.0
    private var inBlock = 0

    /** Feeds the first [count] samples of [pcm]; calls [emit] once per block, carrying partial blocks over. */
    fun feed(pcm: ShortArray, count: Int, emit: (Float) -> Unit) {
        for (i in 0 until count) {
            val s = pcm[i] / 32768.0
            sumSquares += s * s
            inBlock++
            if (inBlock == blockSamples) {
                val target = levelFromRms(sqrt(sumSquares / blockSamples))
                value = if (target > value) value * 0.4f + target * 0.6f else value * 0.8f + target * 0.2f
                emit(value)
                sumSquares = 0.0
                inBlock = 0
            }
        }
    }

    companion object {
        /** Maps an RMS (0..1) to a 0..1 level on a -50..-10 dB scale. */
        fun levelFromRms(rms: Double): Float {
            val db = 20.0 * log10(rms.coerceAtLeast(1e-6))
            return ((db + 50.0) / 40.0).toFloat().coerceIn(0f, 1f)
        }
    }
}

/** Speech heard since the last finished utterance. Zeroed when cleared. */
internal class SpeechBuffer(private val maxSamples: Int) {
    private var data = FloatArray(16_000 * 4)
    var size = 0
        private set

    fun append(chunk: FloatArray) {
        val take = minOf(chunk.size, maxSamples - size)
        if (take <= 0) return
        if (size + take > data.size) data = data.copyOf(maxOf(data.size * 2, size + take))
        System.arraycopy(chunk, 0, data, size, take)
        size += take
    }

    /** A copy of the buffered audio. The caller zeroes it after use. */
    fun copy(): FloatArray = data.copyOf(size)

    fun clear() {
        data.fill(0f, 0, size)
        size = 0
    }
}

/**
 * The last [capacity] samples of everything the microphone heard, indexed from the start of the session.
 * Zeroed when cleared.
 */
internal class AudioHistory(private val capacity: Int) {
    private val ring = FloatArray(capacity)

    /** Samples written since the session started (the index after the newest sample). */
    var total = 0L
        private set

    fun append(chunk: FloatArray) {
        for (sample in chunk) {
            ring[(total % capacity).toInt()] = sample
            total++
        }
    }

    /**
     * A copy of samples [from] until [to], clamped to what is still kept, or null when [mustCover] (a
     * start index) has already been overwritten or lies in the future. The caller zeroes it after use.
     */
    fun slice(from: Long, to: Long, mustCover: Long): FloatArray? {
        val oldest = maxOf(0L, total - capacity)
        if (mustCover < oldest || mustCover >= total) return null
        val a = maxOf(from, oldest)
        val b = minOf(to, total)
        if (b <= a) return null
        return FloatArray((b - a).toInt()) { ring[((a + it) % capacity).toInt()] }
    }

    fun clear() {
        ring.fill(0f)
        total = 0
    }
}

internal class VoiceSession(
    private val mic: Microphone,
    private val engine: SpeechEngine,
    private val main: MainThread,
    private val emit: (VoiceEventMessage) -> Unit,
    private val clock: Clock,
    private val onEnded: () -> Unit,
    private val limits: VoiceLimits = VoiceLimits(),
) {
    /** Audio chunks from the capture thread, then [END]. */
    private val queue = LinkedBlockingQueue<Any>()
    private val stopRequested = AtomicBoolean(false)
    private val cancelRequested = AtomicBoolean(false)
    private val ended = AtomicBoolean(false)
    private val levels = LevelMeter(limits.levelBlockSamples)

    /** Starts both threads. The microphone must already be open. */
    fun start() {
        Thread({ captureLoop() }, "booboard-voice-capture").apply { isDaemon = true }.start()
        Thread({ decodeLoop() }, "booboard-voice-decode").apply { isDaemon = true }.start()
    }

    /** Finish the current utterance, deliver it, then [VoiceEventKind.STOPPED]. */
    fun requestStop() {
        stopRequested.set(true)
    }

    /** Drop everything pending, then [VoiceEventKind.STOPPED]. */
    fun requestCancel() {
        cancelRequested.set(true)
        stopRequested.set(true)
    }

    private fun captureLoop() {
        val pcm = ShortArray(limits.readSamples)
        try {
            while (!stopRequested.get()) {
                val n = mic.read(pcm)
                if (n <= 0) continue
                levels.feed(pcm, n) { level ->
                    main.post { emit(VoiceEventMessage(kind = VoiceEventKind.LEVEL, level = level.toDouble())) }
                }
                val chunk = FloatArray(n) { pcm[it] / 32768f }
                pcm.fill(0, 0, n)
                queue.put(chunk)
            }
        } catch (e: VoiceFailure) {
            fail(e.code)
        } catch (e: SecurityException) {
            fail("permission_revoked")
        } catch (e: Exception) {
            fail("internal")
        } finally {
            pcm.fill(0)
            mic.stop()
            queue.put(END)
        }
    }

    private fun decodeLoop() {
        val speech = SpeechBuffer(limits.maxBufferedSamples)
        val history = AudioHistory(limits.historySamples)
        try {
            engine.resetAudio()
            var totalSamples = 0L
            var silentSamples = 0L
            var lastPartialMs = Long.MIN_VALUE / 2
            var lastPartial = ""
            while (!cancelRequested.get()) {
                val item = queue.poll(limits.pollMs, TimeUnit.MILLISECONDS) ?: continue
                if (item === END) {
                    if (!cancelRequested.get()) {
                        engine.flushAudio()
                        drain(speech, history)
                    }
                    break
                }
                val chunk = item as FloatArray
                totalSamples += chunk.size
                history.append(chunk)
                engine.acceptAudio(chunk)
                val speaking = engine.isSpeaking()
                if (speaking) {
                    silentSamples = 0
                    speech.append(chunk)
                } else {
                    silentSamples += chunk.size
                }
                chunk.fill(0f)
                drain(speech, history)

                // Partial text: re-decode the growing utterance about every 700 ms, but only while the
                // decoder keeps up with the microphone (an empty queue) and the last decode was quick.
                if (speaking && queue.isEmpty() && speech.size >= limits.minPartialSamples) {
                    val now = clock.nowMs()
                    if (now - lastPartialMs >= limits.partialIntervalMs) {
                        val audio = speech.copy()
                        val text = engine.decode(audio)
                        audio.fill(0f)
                        val took = clock.nowMs() - now
                        lastPartialMs = clock.nowMs()
                        if (took <= limits.partialIntervalMs && text.isNotBlank() && text != lastPartial) {
                            lastPartial = text
                            val partial = text.trim()
                            main.post {
                                emit(VoiceEventMessage(kind = VoiceEventKind.PARTIAL, text = partial, level = 0.0))
                            }
                        }
                    }
                }
                if (!speaking && silentSamples >= limits.silenceLimitSamples) requestStop()
                if (totalSamples >= limits.sessionLimitSamples) requestStop()
            }
        } catch (e: VoiceFailure) {
            fail(e.code)
        } catch (e: Exception) {
            fail("model_failed")
        } finally {
            speech.clear()
            history.clear()
            finish()
        }
    }

    /**
     * Decodes every finished utterance and posts its text as a final event. The utterance is decoded with
     * [VoiceLimits.prerollSamples] before and [VoiceLimits.postrollSamples] after it, taken from [history]:
     * without that room the first word after a pause was often lost.
     */
    private fun drain(speech: SpeechBuffer, history: AudioHistory) {
        while (true) {
            val segment = engine.nextSegment() ?: break
            speech.clear()
            val raw = segment.samples
            val text = if (raw.size >= limits.minPartialSamples / 3) {
                val end = segment.start + raw.size
                val padded = history.slice(segment.start - limits.prerollSamples, end + limits.postrollSamples, segment.start)
                val audio = if (padded != null && padded.size >= raw.size) padded else raw
                try {
                    engine.decode(audio)
                } finally {
                    if (audio !== raw) audio.fill(0f)
                }
            } else {
                ""
            }
            raw.fill(0f)
            if (text.isNotBlank()) {
                val final = text.trim()
                main.post { emit(VoiceEventMessage(kind = VoiceEventKind.FINAL_TEXT, text = final, level = 0.0)) }
            }
        }
    }

    private fun fail(code: String) {
        main.post {
            emit(VoiceEventMessage(kind = VoiceEventKind.ERROR, level = 0.0, errorCode = code))
        }
    }

    /** Exactly one `stopped` per session, then the owner's bookkeeping. Also ends the capture. */
    private fun finish() {
        stopRequested.set(true)
        if (!ended.compareAndSet(false, true)) return
        main.post {
            emit(VoiceEventMessage(kind = VoiceEventKind.STOPPED, level = 0.0))
            onEnded()
        }
    }

    private companion object {
        val END = Any()
    }
}
