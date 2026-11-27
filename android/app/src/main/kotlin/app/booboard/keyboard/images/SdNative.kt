// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

/**
 * JNI bridge to stable-diffusion.cpp (libbooboard_images.so, built only for arm64-v8a and x86_64).
 * Runs only inside the `:images` helper process. Never pass or log anything but the prompt to [nativeGenerate].
 */
object SdNative {
    const val RESULT_OK = 0
    const val RESULT_CANCELLED = 1
    const val RESULT_ERROR = 2

    /** Loads libbooboard_images.so; false when this phone's ABI has no engine. */
    fun loadLibrary(): Boolean = try {
        System.loadLibrary("booboard_images")
        true
    } catch (e: UnsatisfiedLinkError) {
        false
    }

    /** Loads the model. Returns a handle, or 0 on failure (see [nativeLastError]). */
    @JvmStatic external fun nativeLoad(modelPath: String, taesdPath: String, threads: Int, listener: SdProgressListener): Long

    /** Makes one picture and writes it as PNG to [outPngPath]. Returns RESULT_OK, RESULT_CANCELLED or RESULT_ERROR. */
    @JvmStatic external fun nativeGenerate(
        handle: Long,
        prompt: String,
        negativePrompt: String,
        seed: Long,
        steps: Int,
        width: Int,
        height: Int,
        cfgScale: Float,
        outPngPath: String,
        listener: SdProgressListener,
    ): Int

    /** Thread-safe: asks the running [nativeGenerate] to stop soon. */
    @JvmStatic external fun nativeCancel(handle: Long)

    /** Frees the model and all native memory for [handle]. */
    @JvmStatic external fun nativeFree(handle: Long)

    /** Last error text (no prompt text in it), or "" if none. */
    @JvmStatic external fun nativeLastError(): String
}
