// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

/** One picture to make. [toString] leaves the prompt out so it can never reach a log by accident. */
data class ImageJob(
    val modelPath: String,
    val taesdPath: String,
    val prompt: String,
    val seed: Long,
    val steps: Int = ImagesProtocol.DEFAULT_STEPS,
    val width: Int = ImagesProtocol.DEFAULT_SIZE,
    val height: Int = ImagesProtocol.DEFAULT_SIZE,
    val cfg: Float = ImagesProtocol.DEFAULT_CFG,
    val outPath: String,
) {
    /** The same job with sizes the engine can take: 1..8 steps, 64..768 pixels in multiples of 8, cfg 0..10. */
    fun sanitized(): ImageJob = copy(
        steps = steps.coerceIn(1, 8),
        width = (width.coerceIn(64, 768) / 8) * 8,
        height = (height.coerceIn(64, 768) / 8) * 8,
        cfg = if (cfg.isNaN()) ImagesProtocol.DEFAULT_CFG else cfg.coerceIn(0f, 10f),
    )

    override fun toString() = "ImageJob(steps=$steps, ${width}x$height)"
}

fun interface ImageProgress {
    /** [phase]: [ImagesProtocol.PHASE_LOADING], PHASE_SAMPLING (step of steps) or PHASE_DECODING. */
    fun onProgress(phase: Int, step: Int, steps: Int)
}

/**
 * The picture engine as the helper sees it. The real one is [SdImageEngine] (stable-diffusion.cpp over JNI);
 * JVM tests use a fake. All calls except [cancel] come from the single worker thread.
 */
interface ImageEngine {
    /** False when this phone has no engine (the native library did not load). */
    fun isAvailable(): Boolean

    /** Loads the model, replacing nothing: the caller frees first. False on failure (see [lastError]). */
    fun load(modelPath: String, taesdPath: String, threads: Int, progress: ImageProgress): Boolean

    /** Makes the picture and writes the PNG to the job's outPath. Returns [SdNative.RESULT_OK], RESULT_CANCELLED or RESULT_ERROR. */
    fun generate(job: ImageJob, progress: ImageProgress): Int

    /** Any thread: asks the running [generate] to stop soon. Does nothing when nothing runs. */
    fun cancel()

    /** Frees the loaded model. Safe to call when nothing is loaded. */
    fun free()

    /** The engine's last error text (never the prompt), or "". */
    fun lastError(): String
}

/** The real engine: stable-diffusion.cpp through [SdNative]. Only ever used inside the `:images` process. */
class SdImageEngine : ImageEngine {
    @Volatile private var handle = 0L
    private val available by lazy { SdNative.loadLibrary() }

    override fun isAvailable() = available

    override fun load(modelPath: String, taesdPath: String, threads: Int, progress: ImageProgress): Boolean {
        handle = SdNative.nativeLoad(modelPath, taesdPath, threads) { phase, step, steps ->
            progress.onProgress(phase, step, steps)
        }
        return handle != 0L
    }

    override fun generate(job: ImageJob, progress: ImageProgress): Int {
        val h = handle
        if (h == 0L) return SdNative.RESULT_ERROR
        return SdNative.nativeGenerate(
            h,
            job.prompt,
            "",
            job.seed,
            job.steps,
            job.width,
            job.height,
            job.cfg,
            job.outPath,
        ) { phase, step, steps -> progress.onProgress(phase, step, steps) }
    }

    override fun cancel() {
        val h = handle
        if (h != 0L) SdNative.nativeCancel(h)
    }

    override fun free() {
        val h = handle
        handle = 0L
        if (h != 0L) SdNative.nativeFree(h)
    }

    override fun lastError(): String = if (available) SdNative.nativeLastError() else ""
}
