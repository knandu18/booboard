// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

import app.booboard.keyboard.bridge.ImageEventKind
import app.booboard.keyboard.bridge.ImageEventMessage
import app.booboard.keyboard.packs.PackManifest
import app.booboard.keyboard.packs.PackStore
import java.io.File

/** Phones whose CPU type has an engine in the APK (see the native build): 64-bit ARM and x86_64 only. */
object ImagesAbi {
    private val SUPPORTED = setOf("arm64-v8a", "x86_64")

    /** [abi] is `Build.SUPPORTED_ABIS[0]`, the phone's preferred ABI. */
    fun supported(abi: String?): Boolean = abi in SUPPORTED
}

/** The model files of the installed image pack. */
data class ImagePackFiles(val modelPath: String, val taesdPath: String)

object ImagesPack {
    const val MODEL = "model/model.gguf"
    const val TAESD = "model/taesd.safetensors"

    /** The first installed pack of kind `image`, when both model files are there; else null (no pack). */
    fun find(packs: PackStore): ImagePackFiles? {
        val dir = packs.find(PackManifest.KIND_IMAGE, emptyList())?.dir ?: return null
        return files(dir)
    }

    fun files(dir: File): ImagePackFiles? {
        val model = File(dir, MODEL)
        val taesd = File(dir, TAESD)
        return if (model.isFile && taesd.isFile) ImagePackFiles(model.path, taesd.path) else null
    }
}

/** Where pictures go: `<cacheDir>/images/<timestamp>.png`, the last few kept. The cache is the system's to clear too. */
object ImagesFiles {
    const val KEEP = 5

    /** A fresh output file in [dir] for a picture made at [nowMillis]; older pictures beyond the limit are deleted. */
    fun newOutput(dir: File, nowMillis: Long): File {
        dir.mkdirs()
        prune(dir, KEEP - 1)
        var file = File(dir, "$nowMillis.png")
        var n = 1
        while (file.exists()) file = File(dir, "$nowMillis-${n++}.png")
        return file
    }

    /** Keeps the [keep] newest pictures in [dir] and deletes the rest, plus anything that is not a picture. */
    fun prune(dir: File, keep: Int) {
        val all = dir.listFiles { f -> f.isFile } ?: return
        val (pictures, others) = all.partition { it.name.endsWith(".png") }
        others.forEach { it.delete() }
        pictures
            .sortedWith(compareByDescending<File> { it.lastModified() }.thenByDescending { it.name })
            .drop(keep.coerceAtLeast(0))
            .forEach { it.delete() }
    }
}

/** Turns the helper's replies into the events Dart gets. */
object ImageReplies {
    /**
     * The event for a helper reply, or null for a message that is not a reply. A progress reply with phase 1
     * is a sampling step; phase 0 is loading and phase 2 decoding.
     */
    fun toEvent(
        what: Int,
        phase: Int = 0,
        step: Int = 0,
        steps: Int = 0,
        path: String? = null,
        millis: Long = 0,
        code: String? = null,
    ): ImageEventMessage? = when (what) {
        ImagesProtocol.MSG_PROGRESS -> when (phase) {
            ImagesProtocol.PHASE_LOADING -> ImageEventMessage(ImageEventKind.LOADING, 0, 0)
            ImagesProtocol.PHASE_SAMPLING -> ImageEventMessage(ImageEventKind.STEP, step.toLong(), steps.toLong())
            ImagesProtocol.PHASE_DECODING -> ImageEventMessage(ImageEventKind.DECODING, 0, 0)
            else -> null
        }

        ImagesProtocol.MSG_DONE ->
            if (path == null) {
                ImageEventMessage(ImageEventKind.ERROR, 0, 0, error = ImagesProtocol.ERR_FAILED)
            } else {
                ImageEventMessage(ImageEventKind.DONE, 0, 0, path = path, millis = millis)
            }

        ImagesProtocol.MSG_CANCELLED -> ImageEventMessage(ImageEventKind.CANCELLED, 0, 0)
        ImagesProtocol.MSG_ERROR -> ImageEventMessage(ImageEventKind.ERROR, 0, 0, error = code ?: ImagesProtocol.ERR_FAILED)
        else -> null
    }

    /** True for the events that end a picture. */
    fun isFinal(event: ImageEventMessage) =
        event.kind == ImageEventKind.DONE || event.kind == ImageEventKind.CANCELLED || event.kind == ImageEventKind.ERROR
}
