// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import android.content.Context
import app.booboard.keyboard.packs.PackStore

/**
 * Offline translation. Interface: orchestrator. Implementation: Wave 3-T (this folder).
 *
 * [translate] runs on a background thread (never the main thread) and may block. Keep at most one
 * model loaded. Never log [text] or the result.
 */
interface TranslationService {
    /** Throws [TranslationException] with code `no_pack` or `failed`. */
    fun translate(text: String, from: String, to: String): String

    fun release()
}

class TranslationException(val code: String, message: String) : Exception(message)

/** The OPUS-MT engine, reading translation packs from [packs]. [context] is kept for the bridge's signature. */
@Suppress("UNUSED_PARAMETER")
fun createTranslationService(context: Context, packs: PackStore): TranslationService = PackTranslationService(packs)
