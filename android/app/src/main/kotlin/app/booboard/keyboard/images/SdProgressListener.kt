// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

/** Called from the native engine thread. [phase]: 0 loading, 1 sampling (step of steps), 2 decoding. */
fun interface SdProgressListener {
    fun onProgress(phase: Int, step: Int, steps: Int)
}
