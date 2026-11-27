// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import java.io.File
import java.nio.FloatBuffer
import java.nio.LongBuffer
import org.json.JSONObject

/** Per-model settings from a translation pack's `model/config.json`. */
internal data class MarianConfig(
    val padId: Int,
    val eosId: Int,
    val unkId: Int,
    val decoderStartId: Int,
    /** A vocabulary token put in front of the source (multilingual OPUS-MT models, e.g. `>>pt<<`), or null. */
    val targetToken: String?,
    val maxLengthFactor: Double,
    val maxExtra: Int,
) {
    companion object {
        fun parse(json: String): MarianConfig {
            val j = JSONObject(json)
            return MarianConfig(
                padId = j.getInt("pad_id"),
                eosId = j.getInt("eos_id"),
                unkId = j.getInt("unk_id"),
                decoderStartId = j.getInt("decoder_start_id"),
                targetToken = if (j.isNull("target_token")) null else j.getString("target_token"),
                maxLengthFactor = j.optDouble("max_length_factor", 1.5),
                maxExtra = j.optInt("max_extra", 10),
            )
        }
    }
}

/**
 * One OPUS-MT (Marian) model: an encoder and a merged decoder with a key/value cache, run by ONNX Runtime,
 * plus the SentencePiece source model and the shared vocabulary. Greedy decoding, one sentence at a time.
 * Not thread-safe: the caller serialises calls. Never logs the text it translates.
 */
internal class OpusMtModel private constructor(
    private val env: OrtEnvironment,
    private val encoder: OrtSession,
    private val decoder: OrtSession,
    private val spm: SentencePieceModel,
    private val ids: Map<String, Int>,
    private val pieces: Array<String?>,
    private val config: MarianConfig,
    /** Shape of each decoder cache input with the sequence length set to zero (first step). */
    private val emptyCacheShapes: Map<String, LongArray>,
) : AutoCloseable {

    /** Translates one sentence. Blank input gives "". */
    fun translate(text: String): String {
        val normalised = SentencePieceModel.normalise(text)
        if (normalised.isEmpty()) return ""
        val head = config.targetToken?.let { listOf(ids[it] ?: throw IllegalStateException("target token")) }.orEmpty()
        val source = head + spm.segment(normalised).map { ids[it] ?: config.unkId } + config.eosId
        val tokens = decode(source.toIntArray())
        return detokenise(tokens)
    }

    override fun close() {
        encoder.close()
        decoder.close()
    }

    private fun decode(source: IntArray): IntArray {
        val n = source.size
        val maxLen = (config.maxLengthFactor * n + config.maxExtra).toInt()
        val shape = longArrayOf(1, n.toLong())
        val inputIds = OnnxTensor.createTensor(env, LongBuffer.wrap(LongArray(n) { source[it].toLong() }), shape)
        val mask = OnnxTensor.createTensor(env, LongBuffer.wrap(LongArray(n) { 1L }), shape)
        try {
            // The encoder result stays open for the whole sentence: the decoder reads its hidden states.
            return encoder.run(mapOf("input_ids" to inputIds, "attention_mask" to mask)).use { enc ->
                decodeSteps(enc.get(0) as OnnxTensor, mask, maxLen)
            }
        } finally {
            inputIds.close()
            mask.close()
        }
    }

    /** Greedy steps with the key/value cache. The first step gets empty caches and `use_cache_branch` false. */
    private fun decodeSteps(hidden: OnnxTensor, mask: OnnxTensor, maxLen: Int): IntArray {
        val out = IntArray(maxLen)
        var count = 0
        // Encoder caches come from the first step and are copied, so the first result can be closed early.
        val encoderCache = HashMap<String, OnnxTensor>()
        var decoderCache: Map<String, OnnxTensor> = emptyMap()
        var previous: OrtSession.Result? = null
        var token = config.decoderStartId
        try {
            for (step in 0 until maxLen) {
                val stepInputs = ArrayList<OnnxTensor>()
                val feed = LinkedHashMap<String, OnnxTensor>()
                feed["encoder_attention_mask"] = mask
                feed["encoder_hidden_states"] = hidden
                val tokenTensor = OnnxTensor.createTensor(env, LongBuffer.wrap(longArrayOf(token.toLong())), longArrayOf(1, 1))
                stepInputs += tokenTensor
                feed["input_ids"] = tokenTensor
                val cacheFlag = OnnxTensor.createTensor(env, booleanArrayOf(step > 0))
                stepInputs += cacheFlag
                feed["use_cache_branch"] = cacheFlag
                if (step == 0) {
                    for ((name, shape) in emptyCacheShapes) {
                        val empty = OnnxTensor.createTensor(env, FloatBuffer.allocate(0), shape)
                        stepInputs += empty
                        feed[name] = empty
                    }
                } else {
                    feed.putAll(decoderCache)
                    feed.putAll(encoderCache)
                }
                val result = decoder.run(feed)
                try {
                    val logits = result.get("logits").get() as OnnxTensor
                    token = argmax(logits.floatBuffer, config.padId)
                    if (count < out.size) out[count++] = token
                    if (step == 0) {
                        for (entry in result) {
                            val name = entry.key
                            if (name.startsWith("present.") && name.contains(".encoder.")) {
                                encoderCache[name.replaceFirst("present.", PAST)] = copyOf(entry.value as OnnxTensor)
                            }
                        }
                    }
                    decoderCache = buildMap {
                        for (entry in result) {
                            val name = entry.key
                            if (name.startsWith("present.") && name.contains(".decoder.")) {
                                put(name.replaceFirst("present.", PAST), entry.value as OnnxTensor)
                            }
                        }
                    }
                } finally {
                    stepInputs.forEach { it.close() }
                    previous?.close()
                    previous = result
                }
                if (token == config.eosId) break
            }
        } finally {
            previous?.close()
            encoderCache.values.forEach { it.close() }
        }
        return out.copyOf(count)
    }

    private fun copyOf(src: OnnxTensor): OnnxTensor {
        val buf = src.floatBuffer.duplicate()
        val values = FloatArray(buf.remaining())
        buf.get(values)
        return OnnxTensor.createTensor(env, FloatBuffer.wrap(values), src.info.shape)
    }

    private fun argmax(logits: FloatBuffer, skip: Int): Int {
        var best = 0
        var bestValue = Float.NEGATIVE_INFINITY
        for (i in 0 until logits.capacity()) {
            if (i == skip) continue
            val v = logits.get(i)
            if (v > bestValue) {
                bestValue = v
                best = i
            }
        }
        return best
    }

    private fun detokenise(tokens: IntArray): String {
        val sb = StringBuilder()
        for (id in tokens) {
            if (id == config.eosId || id == config.unkId || id == config.padId) continue
            pieces.getOrNull(id)?.let { sb.append(it) }
        }
        return sb.toString().replace(SentencePieceModel.SPACE, " ").trim()
    }

    companion object {
        private const val PAST = "past_key_values."

        /**
         * Loads the model files in [dir] (`encoder.onnx`, `decoder.onnx`, `source.spm`, `vocab.json`). Throws on
         * missing or unreadable files; the caller maps that to a failed translation.
         */
        fun load(env: OrtEnvironment, dir: File, config: MarianConfig, threads: Int): OpusMtModel {
            val spm = SentencePieceModel.parse(File(dir, "source.spm").readBytes())
            val (ids, pieces) = readVocab(File(dir, "vocab.json").readText(Charsets.UTF_8))
            val encoder: OrtSession
            val decoder: OrtSession
            val options = OrtSession.SessionOptions()
            try {
                options.setIntraOpNumThreads(threads)
                encoder = env.createSession(File(dir, "encoder.onnx").path, options)
                decoder = env.createSession(File(dir, "decoder.onnx").path, options)
            } finally {
                options.close()
            }
            val shapes = HashMap<String, LongArray>()
            for (name in decoder.inputNames) {
                if (!name.startsWith(PAST)) continue
                val shape = (decoder.inputInfo.getValue(name).info as TensorInfo).shape
                shapes[name] = longArrayOf(1, shape[1], 0, shape[3])
            }
            return OpusMtModel(env, encoder, decoder, spm, ids, pieces, config, shapes)
        }

        /** Token to id, and id to token (null for ids the vocabulary does not use). */
        internal fun readVocab(json: String): Pair<Map<String, Int>, Array<String?>> {
            val obj = JSONObject(json)
            val ids = HashMap<String, Int>(obj.length() * 2)
            var max = 0
            val keys = obj.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val id = obj.getInt(key)
                ids[key] = id
                if (id > max) max = id
            }
            val pieces = arrayOfNulls<String>(max + 1)
            for ((piece, id) in ids) pieces[id] = piece
            return ids to pieces
        }
    }
}
