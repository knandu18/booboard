// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import ai.onnxruntime.OrtEnvironment
import android.util.Log
import app.booboard.keyboard.packs.InstalledPack
import app.booboard.keyboard.packs.PackManifest
import app.booboard.keyboard.packs.PackStore
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Offline translation with OPUS-MT models from installed translation packs (`translate-<from>-<to>`).
 * One model is loaded at a time and freed after [IDLE_RELEASE_MS] without a translation. Calls are serialised
 * by [translate] and [release] being synchronized, and the bridge runs them off the main thread.
 * Never logs the text, only sizes and timings.
 */
internal class PackTranslationService(private val packs: PackStore) : TranslationService {
    private val idle: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "booboard-translate-idle").apply { isDaemon = true }
    }
    private var loadedPackId: String? = null
    private var model: OpusMtModel? = null
    private var idleRelease: ScheduledFuture<*>? = null

    @Synchronized
    override fun translate(text: String, from: String, to: String): String {
        val source = packLanguage(from)
        val target = packLanguage(to)
        val pack = findPack(source, target)
            ?: throw TranslationException("no_pack", "no translation pack for $source-$target")
        val started = System.nanoTime()
        val engine = engineFor(pack)
        val sentences = splitSentences(text)
        val result = sentences.joinToString(" ") { engine.translate(it) }
        scheduleRelease()
        timing("translated ${text.length} chars in ${sentences.size} sentences, ${millisSince(started)} ms")
        return result
    }

    @Synchronized
    override fun release() {
        idleRelease?.cancel(false)
        idleRelease = null
        model?.close()
        model = null
        loadedPackId = null
    }

    /** The installed pack whose languages are exactly [source] then [target] (the direction matters). */
    private fun findPack(source: String, target: String): InstalledPack? =
        packs.list().firstOrNull {
            it.manifest.kind == PackManifest.KIND_TRANSLATION && it.manifest.languages == listOf(source, target)
        }

    private fun engineFor(pack: InstalledPack): OpusMtModel {
        val current = model
        if (current != null && loadedPackId == pack.manifest.id) return current
        release()
        val dir = File(pack.dir, "model")
        val config = MarianConfig.parse(File(dir, "config.json").readText(Charsets.UTF_8))
        val started = System.nanoTime()
        val loaded = OpusMtModel.load(OrtEnvironment.getEnvironment(), dir, config, threads = THREADS)
        timing("loaded model in ${millisSince(started)} ms")
        model = loaded
        loadedPackId = pack.manifest.id
        return loaded
    }

    private fun scheduleRelease() {
        idleRelease?.cancel(false)
        idleRelease = idle.schedule(Runnable { release() }, IDLE_RELEASE_MS, TimeUnit.MILLISECONDS)
    }

    private fun millisSince(startNanos: Long): Long = (System.nanoTime() - startNanos) / 1_000_000

    /** Timings only. Logging must never break a translation (unit tests have no android.util.Log). */
    private fun timing(message: String) {
        runCatching { Log.d(TAG, message) }
    }

    companion object {
        private const val TAG = "BooBoardTranslate"
        private const val THREADS = 2
        const val IDLE_RELEASE_MS = 2 * 60 * 1000L
    }
}

/** BooBoard language ids that share a translation pack: Brazilian and European Portuguese use the `pt` models. */
internal fun packLanguage(id: String): String = when (id) {
    "pt-BR", "pt-PT" -> "pt"
    else -> id
}

private const val MAX_SENTENCE_CHARS = 240
private val SENTENCE_BREAK = Regex("(?<=[.!?。！？।؟])\\s+|\\n+")

/**
 * Sentences for the model, in order. Long runs without punctuation are cut at word boundaries so one call stays
 * well inside the model's context.
 */
internal fun splitSentences(text: String): List<String> =
    text.split(SENTENCE_BREAK)
        .map { it.trim() }
        .filter { it.isNotEmpty() }
        .flatMap { chunkAtWords(it) }

private fun chunkAtWords(sentence: String): List<String> {
    if (sentence.length <= MAX_SENTENCE_CHARS) return listOf(sentence)
    val out = ArrayList<String>()
    val current = StringBuilder()
    for (word in sentence.split(' ')) {
        if (current.isNotEmpty() && current.length + 1 + word.length > MAX_SENTENCE_CHARS) {
            out.add(current.toString())
            current.clear()
        }
        if (current.isNotEmpty()) current.append(' ')
        current.append(word)
    }
    if (current.isNotEmpty()) out.add(current.toString())
    return out
}
