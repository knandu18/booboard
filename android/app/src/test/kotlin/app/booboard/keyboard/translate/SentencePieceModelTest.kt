// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import java.io.ByteArrayOutputStream
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test

class SentencePieceModelTest {

    @Test
    fun normaliseAddsWordMarkersAndCollapsesSpaces() {
        assertEquals("▁Hello,▁world!", SentencePieceModel.normalise("  Hello,  world!  "))
        assertEquals("", SentencePieceModel.normalise("   "))
    }

    @Test
    fun normaliseUsesNfkc() {
        // The ellipsis character becomes three dots, and a precomposed e-acute stays as it is.
        assertEquals("▁Café▁ok...", SentencePieceModel.normalise("Café ok…"))
    }

    @Test
    fun segmentPrefersTheHighestScoringPieces() {
        val whole = SentencePieceModel.parse(spm(piece("▁ab", -1f), piece("▁a", -2f), piece("b", -2f)))
        assertEquals(listOf("▁ab"), whole.segment("▁ab"))
        // Without "▁ab" the two pieces "▁a" and "b" (total -4) are the only way to cover the word.
        val split = SentencePieceModel.parse(spm(piece("▁a", -2f), piece("b", -2f), piece("▁", -5f)))
        assertEquals(listOf("▁a", "b"), split.segment("▁ab"))
    }

    @Test
    fun uncoveredCharactersStayAsSingleTokens() {
        val model = SentencePieceModel.parse(spm(piece("▁", -5f), piece("x", -3f)))
        // "ü" has no piece: it becomes a token of its own, in code points (an emoji is one token).
        assertEquals(listOf("▁", "x", "ü", "😀"), model.segment("▁xü😀"))
    }

    @Test
    fun parseSkipsUnknownFieldsAndControlPieces() {
        val bytes = spm(piece("<unk>", 0f, type = 2), piece("</s>", 0f, type = 3), piece("▁a", -1f), trainerSpec())
        val model = SentencePieceModel.parse(bytes)
        assertEquals(listOf("▁a"), model.segment("▁a"))
    }

    @Test
    fun readsMultiByteVarints() {
        val reader = ProtoReader(byteArrayOf(0xac.toByte(), 0x02))
        assertEquals(300L, reader.varint())
        assertTrue(reader.atEnd())
    }

    @Test
    fun realSourceModelSegmentsLikeSentencePiece() {
        val dir = packDir("translate-en-es")
        val model = SentencePieceModel.parse(File(dir, "source.spm").readBytes())
        // Reference segmentation from sentencepiece 0.2 for the same models (dev-time check).
        assertEquals(
            listOf("▁Where", "▁is", "▁the", "▁station", "?"),
            model.segment(SentencePieceModel.normalise("Where is the station?")),
        )
        assertEquals(
            listOf("▁Hello", ",", "▁world", "!", "▁Café", "▁na", "ï", "ve", "▁—", "▁ok", "..."),
            model.segment(SentencePieceModel.normalise("Hello,  world!  Café naïve — ok…")),
        )
    }

    /** The `model/` folder of a staged translation pack. Real-model tests are skipped without BOOBOARD_TRANSLATE_PACKS. */
    private fun packDir(pack: String): File {
        val root = System.getenv("BOOBOARD_TRANSLATE_PACKS")
        assumeTrue("set BOOBOARD_TRANSLATE_PACKS to run the real-model tests", root != null)
        val dir = File(root, "$pack/model")
        assumeTrue("$pack is not staged", dir.isDirectory)
        return dir
    }

    // ---- protobuf helpers for a minimal ModelProto ---------------------------------------

    private fun piece(text: String, score: Float, type: Int = 1): ByteArray {
        val out = ByteArrayOutputStream()
        writeLen(out, 1, text.toByteArray(Charsets.UTF_8))
        writeTag(out, 2, 5)
        val bits = java.lang.Float.floatToIntBits(score)
        for (i in 0 until 4) out.write((bits ushr (8 * i)) and 0xff)
        writeTag(out, 3, 0)
        writeVarint(out, type.toLong())
        return out.toByteArray()
    }

    private fun trainerSpec(): ByteArray {
        val out = ByteArrayOutputStream()
        writeLen(out, 2, ByteArray(40) { 7 })
        return out.toByteArray()
    }

    private fun spm(vararg pieces: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        for (p in pieces) writeLen(out, 1, p)
        return out.toByteArray()
    }

    private fun writeTag(out: ByteArrayOutputStream, field: Int, wire: Int) = writeVarint(out, ((field shl 3) or wire).toLong())

    private fun writeLen(out: ByteArrayOutputStream, field: Int, data: ByteArray) {
        writeTag(out, field, 2)
        writeVarint(out, data.size.toLong())
        out.write(data)
    }

    private fun writeVarint(out: ByteArrayOutputStream, value: Long) {
        var v = value
        while (v >= 0x80) {
            out.write(((v and 0x7f) or 0x80).toInt())
            v = v ushr 7
        }
        out.write(v.toInt())
    }
}
