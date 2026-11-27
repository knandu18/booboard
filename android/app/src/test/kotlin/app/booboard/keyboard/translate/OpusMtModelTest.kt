// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import ai.onnxruntime.OrtEnvironment
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assume.assumeTrue
import org.junit.Test

/**
 * Real OPUS-MT models through ONNX Runtime. They need the staged packs: set BOOBOARD_TRANSLATE_PACKS to the folder that
 * holds `translate-en-es/`, `translate-en-pt/` (see tool/packs/translate/stage.ps1). Without it the tests are skipped.
 * The expected token ids come from the sentencepiece library and the Hugging Face tokenizer (dev-time check).
 */
class OpusMtModelTest {

    @Test
    fun tokenisesLikeTheReferenceTokenizer() {
        val dir = packDir("translate-en-es")
        val spm = SentencePieceModel.parse(File(dir, "source.spm").readBytes())
        val (ids, _) = OpusMtModel.readVocab(File(dir, "vocab.json").readText(Charsets.UTF_8))
        assertEquals(
            listOf(1320, 31, 5, 4466, 21),
            spm.segment(SentencePieceModel.normalise("Where is the station?")).map { ids.getValue(it) },
        )
        assertEquals(
            listOf(42, 7693, 17127, 41587, 13433, 9, 271, 5, 43891, 6913, 3),
            spm.segment(SentencePieceModel.normalise("The quick brown fox jumps over the lazy dog.")).map { ids.getValue(it) },
        )
    }

    @Test
    fun englishToSpanish() {
        val dir = packDir("translate-en-es")
        open(dir).use { model ->
            assertEquals("¿Dónde está la estación?", model.translate("Where is the station?"))
            assertEquals("Buenos días, ¿cómo estás hoy?", model.translate("Good morning, how are you today?"))
            assertEquals("El zorro marrón salta sobre el perro perezoso.", model.translate("The quick brown fox jumps over the lazy dog."))
            assertEquals("", model.translate("   "))
        }
    }

    @Test
    fun spanishToEnglish() {
        val dir = packDir("translate-es-en")
        open(dir).use { model ->
            assertEquals("Where's the station?", model.translate("¿Dónde está la estación?"))
        }
    }

    @Test
    fun englishToPortugueseUsesTheTargetToken() {
        val dir = packDir("translate-en-pt")
        open(dir).use { model ->
            assertEquals("Onde fica a estação?", model.translate("Where is the station?"))
        }
    }

    @Test
    fun configReadsTheTargetToken() {
        val config = MarianConfig.parse(
            """{"pad_id":65000,"eos_id":0,"unk_id":1,"decoder_start_id":65000,"target_token":">>pt<<"}""",
        )
        assertEquals(">>pt<<", config.targetToken)
        assertEquals(1.5, config.maxLengthFactor, 0.0)
        assertEquals(10, config.maxExtra)
        val plain = MarianConfig.parse("""{"pad_id":1,"eos_id":0,"unk_id":1,"decoder_start_id":1,"target_token":null}""")
        assertEquals(null, plain.targetToken)
    }

    private fun open(dir: File): OpusMtModel {
        val config = MarianConfig.parse(File(dir, "config.json").readText(Charsets.UTF_8))
        return OpusMtModel.load(OrtEnvironment.getEnvironment(), dir, config, threads = 2)
    }

    private fun packDir(pack: String): File {
        val root = System.getenv("BOOBOARD_TRANSLATE_PACKS")
        assumeTrue("set BOOBOARD_TRANSLATE_PACKS to run the real-model tests", root != null)
        val dir = File(root, "$pack/model")
        assumeTrue("$pack is not staged", dir.isDirectory)
        return dir
    }
}
