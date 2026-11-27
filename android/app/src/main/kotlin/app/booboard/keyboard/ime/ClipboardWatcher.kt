// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.ime

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.util.Log
import app.booboard.keyboard.bridge.ClipMessage

/** Converts a system clip into the bridge message, or null when BooBoard must ignore it. */
internal object ClipReader {
    /** Longer clips are skipped entirely (a truncated secret is worse than none). */
    const val MAX_CHARS = 20_000

    /** `ClipDescription.EXTRA_IS_SENSITIVE`, spelled out so it also works before API 33. */
    private const val EXTRA_IS_SENSITIVE = "android.content.extra.IS_SENSITIVE"

    fun read(clip: ClipData?): ClipMessage? {
        if (clip == null || clip.itemCount == 0) return null
        val desc = clip.description
        // Text only. Never resolve URIs or intents: that could touch other apps' content.
        if (!desc.hasMimeType("text/*")) return null
        val text = clip.getItemAt(0).text?.toString() ?: return null
        if (!acceptable(text.length)) return null
        val sensitive = desc.extras?.getBoolean(EXTRA_IS_SENSITIVE, false) == true
        return ClipMessage(text, desc.timestamp, sensitive)
    }

    fun acceptable(length: Int): Boolean = length in 1..MAX_CHARS
}

/**
 * Listens to clipboard changes for the lifetime of the service and forwards text clips to Dart.
 * Clip content is never logged.
 */
internal class ClipboardWatcher(
    context: Context,
    private val onClip: (ClipMessage) -> Unit,
) {
    private val manager = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
    private var registered = false

    // Some devices report one copy twice. Remember only metadata, never the text.
    private var lastTimestamp = -1L
    private var lastLength = -1

    private val listener = ClipboardManager.OnPrimaryClipChangedListener { handleChange() }

    fun start() {
        if (registered) return
        manager?.addPrimaryClipChangedListener(listener)
        registered = manager != null
    }

    fun stop() {
        if (!registered) return
        manager?.removePrimaryClipChangedListener(listener)
        registered = false
    }

    private fun handleChange() {
        val message = try {
            ClipReader.read(manager?.primaryClip)
        } catch (e: Exception) {
            // SecurityException when the system denies background access; nothing to forward.
            Log.w(TAG, "clipboard read failed: ${e.javaClass.simpleName}")
            null
        } ?: return
        if (message.timestampMillis == lastTimestamp && message.text.length == lastLength) return
        lastTimestamp = message.timestampMillis
        lastLength = message.text.length
        onClip(message)
    }

    private companion object {
        const val TAG = "BooBoardClipboard"
    }
}
