// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

import java.io.File
import java.util.concurrent.Executor
import java.util.concurrent.atomic.AtomicBoolean

/**
 * The helper's logic without any Android classes, so JVM tests can drive it with a fake [ImageEngine].
 *
 * One picture at a time. The picture runs on [executor], which must be a single thread (the service gives it a
 * low-priority one), together with every load and free of the model, so the engine is never entered twice.
 * The loaded model stays cached for the next picture until [freeIfIdle] or [shutdown] frees it.
 * Each accepted [make] ends with exactly one of [Listener.onDone], [Listener.onCancelled] or [Listener.onError],
 * called on the worker thread after the worker is free again, so the next [make] can follow at once.
 * Never logs the prompt.
 */
class ImagesWorker(
    private val engine: ImageEngine,
    private val executor: Executor,
    private val threads: Int,
    private val now: () -> Long,
    private val listener: Listener,
) {
    interface Listener {
        fun onProgress(phase: Int, step: Int, steps: Int)

        fun onDone(outPath: String, millis: Long)

        fun onCancelled()

        /** [code] is one of [ImagesProtocol] ERR_*; [detail] is the engine's last error text, never the prompt. */
        fun onError(code: String, detail: String)
    }

    private val busy = AtomicBoolean(false)

    @Volatile private var cancelRequested = false

    /** When the last picture finished (or the worker started); the idle clock. */
    @Volatile private var lastActiveAt = now()

    /** The model files the engine currently holds; written on the worker thread only. */
    @Volatile private var loadedKey: String? = null

    val isBusy: Boolean get() = busy.get()

    /** True while the engine holds a model. */
    val isLoaded: Boolean get() = loadedKey != null

    /** Starts [job]. False (and an ERR_BUSY error) when a picture is already being made. */
    fun make(job: ImageJob): Boolean {
        if (!busy.compareAndSet(false, true)) {
            listener.onError(ImagesProtocol.ERR_BUSY, "")
            return false
        }
        cancelRequested = false
        val clean = job.sanitized()
        executor.execute { run(clean) }
        return true
    }

    /** Asks the running picture to stop. Does nothing when idle. */
    fun stop() {
        if (!busy.get()) return
        cancelRequested = true
        engine.cancel()
    }

    /**
     * Frees the model when nothing is being made. [force] frees it at once (memory is low); otherwise only when
     * the last picture was at least [ImagesProtocol.IDLE_FREE_MS] ago.
     */
    fun freeIfIdle(force: Boolean) {
        if (busy.get()) return
        executor.execute {
            if (busy.get()) return@execute
            if (!force && now() - lastActiveAt < ImagesProtocol.IDLE_FREE_MS) return@execute
            freeModel()
        }
    }

    /** The helper is ending: stop any picture and free the model after it. */
    fun shutdown() {
        if (busy.get()) {
            cancelRequested = true
            engine.cancel()
        }
        executor.execute { freeModel() }
    }

    private fun freeModel() {
        if (loadedKey == null) return
        loadedKey = null
        try {
            engine.free()
        } catch (e: Throwable) {
            // Nothing to do: the process is about to end or the model is gone already.
        }
    }

    private sealed interface Outcome {
        data class Done(val outPath: String, val millis: Long) : Outcome

        data object Cancelled : Outcome

        data class Failed(val code: String, val detail: String) : Outcome
    }

    private fun run(job: ImageJob) {
        val started = now()
        val progress = ImageProgress { phase, step, steps -> listener.onProgress(phase, step, steps) }
        val outcome = try {
            produce(job, started, progress)
        } catch (e: Throwable) {
            // Includes OutOfMemoryError. Only the type name: exceptions from native code can carry paths.
            freeModel()
            deleteQuietly(job.outPath)
            Outcome.Failed(ImagesProtocol.ERR_FAILED, e.javaClass.simpleName)
        }
        // Report after busy is cleared (see the class comment).
        lastActiveAt = now()
        busy.set(false)
        when (outcome) {
            is Outcome.Done -> listener.onDone(outcome.outPath, outcome.millis)
            Outcome.Cancelled -> listener.onCancelled()
            is Outcome.Failed -> listener.onError(outcome.code, outcome.detail)
        }
    }

    private fun produce(job: ImageJob, started: Long, progress: ImageProgress): Outcome {
        if (!engine.isAvailable()) return Outcome.Failed(ImagesProtocol.ERR_UNSUPPORTED, "")
        val key = job.modelPath + '|' + job.taesdPath
        if (loadedKey != key) {
            freeModel()
            progress.onProgress(ImagesProtocol.PHASE_LOADING, 0, 0)
            if (!engine.load(job.modelPath, job.taesdPath, threads, progress)) {
                return Outcome.Failed(ImagesProtocol.ERR_LOAD_FAILED, engine.lastError())
            }
            loadedKey = key
        }
        if (cancelRequested) return Outcome.Cancelled
        return when (engine.generate(job, progress)) {
            SdNative.RESULT_OK -> Outcome.Done(job.outPath, now() - started)
            SdNative.RESULT_CANCELLED -> {
                deleteQuietly(job.outPath)
                Outcome.Cancelled
            }
            else -> {
                deleteQuietly(job.outPath)
                Outcome.Failed(ImagesProtocol.ERR_FAILED, engine.lastError())
            }
        }
    }

    private fun deleteQuietly(path: String) {
        try {
            File(path).delete()
        } catch (e: SecurityException) {
            // Ignored: a leftover picture is pruned later.
        }
    }
}
