// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

/**
 * The messages between the keyboard process ([ImagesClient]) and the `:images` helper ([ImagesService]).
 * Plain `Messenger` messages: `what` is one of the MSG_ numbers and `data` holds the KEY_ values.
 * Constants only, so JVM tests can use it.
 *
 * Keyboard -> helper:
 *  - [MSG_MAKE] KEY_MODEL, KEY_TAESD, KEY_PROMPT, KEY_SEED, KEY_STEPS, KEY_WIDTH, KEY_HEIGHT, KEY_CFG, KEY_OUT;
 *    `replyTo` is where the answers go. A second MAKE while one runs is answered with [MSG_ERROR] [ERR_BUSY].
 *  - [MSG_STOP] nothing; answered with [MSG_CANCELLED] (or the result, if it was already done).
 *
 * Helper -> keyboard:
 *  - [MSG_PROGRESS] KEY_PHASE (PHASE_*), KEY_STEP, KEY_STEPS.
 *  - [MSG_DONE] KEY_OUT, KEY_MILLIS (loading plus making).
 *  - [MSG_CANCELLED] nothing.
 *  - [MSG_ERROR] KEY_CODE (ERR_*), KEY_DETAIL (the engine's last error text; never the prompt).
 *
 * Exactly one of DONE, CANCELLED or ERROR ends every accepted MAKE.
 */
object ImagesProtocol {
    const val MSG_MAKE = 1
    const val MSG_STOP = 2

    const val MSG_PROGRESS = 10
    const val MSG_DONE = 11
    const val MSG_CANCELLED = 12
    const val MSG_ERROR = 13

    const val KEY_MODEL = "modelPath"
    const val KEY_TAESD = "taesdPath"
    const val KEY_PROMPT = "prompt"
    const val KEY_SEED = "seed"
    const val KEY_STEPS = "steps"
    const val KEY_WIDTH = "width"
    const val KEY_HEIGHT = "height"
    const val KEY_CFG = "cfg"
    const val KEY_OUT = "outPath"

    const val KEY_PHASE = "phase"
    const val KEY_STEP = "step"
    const val KEY_MILLIS = "millis"
    const val KEY_CODE = "code"
    const val KEY_DETAIL = "detail"

    const val PHASE_LOADING = 0
    const val PHASE_SAMPLING = 1
    const val PHASE_DECODING = 2

    /** No engine on this phone: the library did not load. */
    const val ERR_UNSUPPORTED = "unsupported"
    const val ERR_LOAD_FAILED = "load_failed"
    const val ERR_FAILED = "failed"
    const val ERR_BUSY = "busy"

    /** Made by the keyboard side when the helper process disappeared (most likely closed for memory). */
    const val ERR_HELPER_DIED = "helper_died"

    const val DEFAULT_STEPS = 4
    const val DEFAULT_SIZE = 512
    const val DEFAULT_CFG = 1.0f

    /** The helper frees the loaded model after this long without a picture. */
    const val IDLE_FREE_MS = 60_000L

    /** The keyboard unbinds (so the helper process can end) this long after the last result. */
    const val CLIENT_UNBIND_MS = 75_000L

    /** Threads for the engine: leave one core to the phone, between 2 and 6. */
    fun engineThreads(cpus: Int): Int = (cpus - 1).coerceIn(2, 6)
}
