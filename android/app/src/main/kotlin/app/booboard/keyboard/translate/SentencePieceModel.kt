// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import java.text.Normalizer

/**
 * The unigram SentencePiece model of an OPUS-MT source side (`source.spm`), read directly from its protobuf
 * (`ModelProto`, field 1 = pieces). Only the pieces and their scores are used: [segment] is the Viterbi search
 * SentencePiece runs, and [normalise] is the NFKC normalisation these models declare.
 */
internal class SentencePieceModel private constructor(
    private val scores: Map<String, Float>,
    private val maxPieceChars: Int,
    private val minScore: Float,
) {
    /**
     * Splits [normalised] text (see [normalise]) into pieces with the best total score. A character that no
     * piece covers stays as one token of its own, so the vocabulary can still map it.
     */
    fun segment(normalised: String): List<String> {
        val cps = normalised.codePoints().toArray()
        val n = cps.size
        if (n == 0) return emptyList()
        val best = FloatArray(n + 1) { Float.NEGATIVE_INFINITY }
        val fromIndex = IntArray(n + 1)
        val fromPiece = arrayOfNulls<String>(n + 1)
        best[0] = 0f
        for (i in 0 until n) {
            var coveredSingle = false
            val last = minOf(n, i + maxPieceChars)
            for (j in i + 1..last) {
                val piece = String(cps, i, j - i)
                val score = scores[piece] ?: continue
                if (j == i + 1) coveredSingle = true
                val candidate = best[i] + score
                if (candidate > best[j]) {
                    best[j] = candidate
                    fromIndex[j] = i
                    fromPiece[j] = piece
                }
            }
            if (!coveredSingle) {
                val candidate = best[i] + minScore - UNK_PENALTY
                if (candidate > best[i + 1]) {
                    best[i + 1] = candidate
                    fromIndex[i + 1] = i
                    fromPiece[i + 1] = String(cps, i, 1)
                }
            }
        }
        val out = ArrayList<String>()
        var j = n
        while (j > 0) {
            out.add(fromPiece[j] ?: break)
            j = fromIndex[j]
        }
        out.reverse()
        return out
    }

    companion object {
        /** SentencePiece's word-boundary marker. */
        const val SPACE = "▁"

        private const val UNK_PENALTY = 10f
        private const val TYPE_NORMAL = 1
        private const val TYPE_USER_DEFINED = 4
        private const val WIRE_VARINT = 0
        private const val WIRE_LEN = 2
        private const val WIRE_I32 = 5
        private val WHITESPACE = Regex("\\p{javaWhitespace}+")

        /** NFKC, runs of whitespace collapsed, and a space marker in front of every word. */
        fun normalise(text: String): String {
            val words = Normalizer.normalize(text, Normalizer.Form.NFKC).split(WHITESPACE).filter { it.isNotEmpty() }
            return if (words.isEmpty()) "" else SPACE + words.joinToString(SPACE)
        }

        /** Reads a `source.spm` file. Throws [IllegalArgumentException] when the bytes are not a model. */
        fun parse(bytes: ByteArray): SentencePieceModel {
            val scores = HashMap<String, Float>()
            var maxChars = 1
            var minScore = 0f
            val top = ProtoReader(bytes)
            while (!top.atEnd()) {
                val tag = top.varint()
                val field = (tag ushr 3).toInt()
                val wire = (tag and 7).toInt()
                if (field != 1 || wire != WIRE_LEN) {
                    top.skip(wire)
                    continue
                }
                val piece = ProtoReader(top.bytes())
                var text: String? = null
                var score = 0f
                var type = TYPE_NORMAL
                while (!piece.atEnd()) {
                    val t = piece.varint()
                    val f = (t ushr 3).toInt()
                    val w = (t and 7).toInt()
                    when {
                        f == 1 && w == WIRE_LEN -> text = String(piece.bytes(), Charsets.UTF_8)
                        f == 2 && w == WIRE_I32 -> score = Float.fromBits(piece.fixed32())
                        f == 3 && w == WIRE_VARINT -> type = piece.varint().toInt()
                        else -> piece.skip(w)
                    }
                }
                val p = text ?: continue
                minScore = minOf(minScore, score)
                if (type == TYPE_NORMAL || type == TYPE_USER_DEFINED) {
                    scores[p] = score
                    maxChars = maxOf(maxChars, p.codePointCount(0, p.length))
                }
            }
            require(scores.isNotEmpty()) { "no pieces" }
            return SentencePieceModel(scores, maxChars, minScore)
        }
    }
}

/** Minimal protobuf wire-format reader: varints, length-delimited fields and fixed 32/64-bit values. */
internal class ProtoReader(private val b: ByteArray) {
    private var pos = 0

    fun atEnd(): Boolean = pos >= b.size

    fun varint(): Long {
        var result = 0L
        var shift = 0
        while (true) {
            require(pos < b.size && shift < 64) { "bad varint" }
            val x = b[pos++].toInt()
            result = result or ((x and 0x7f).toLong() shl shift)
            if ((x and 0x80) == 0) return result
            shift += 7
        }
    }

    fun fixed32(): Int {
        require(pos + 4 <= b.size) { "truncated" }
        val v = (b[pos].toInt() and 0xff) or
            ((b[pos + 1].toInt() and 0xff) shl 8) or
            ((b[pos + 2].toInt() and 0xff) shl 16) or
            ((b[pos + 3].toInt() and 0xff) shl 24)
        pos += 4
        return v
    }

    fun bytes(): ByteArray {
        val len = varint()
        require(len >= 0 && len <= b.size - pos) { "bad length" }
        val out = b.copyOfRange(pos, pos + len.toInt())
        pos += len.toInt()
        return out
    }

    fun skip(wire: Int) {
        when (wire) {
            0 -> varint()
            1 -> pos += 8
            2 -> bytes()
            5 -> pos += 4
            else -> throw IllegalArgumentException("unsupported wire type")
        }
        require(pos <= b.size) { "truncated" }
    }
}
