// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import app.booboard.keyboard.packs.InstalledPack
import app.booboard.keyboard.packs.PackManifest
import java.io.File
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class VoiceLanguagesTest {
    @Test
    fun englishAndEveryEnglishVariantCount() {
        assertTrue(VoiceLanguages.isEnglish("en"))
        assertTrue(VoiceLanguages.isEnglish("en-GB"))
        assertTrue(VoiceLanguages.isEnglish("en-IN"))
        assertTrue(VoiceLanguages.isEnglish("EN-us"))
    }

    @Test
    fun otherLanguagesAndMissingLanguagesDoNotCount() {
        assertFalse(VoiceLanguages.isEnglish(null))
        assertFalse(VoiceLanguages.isEnglish(""))
        assertFalse(VoiceLanguages.isEnglish("   "))
        assertFalse(VoiceLanguages.isEnglish("hi"))
        assertFalse(VoiceLanguages.isEnglish("pt-BR"))
        assertFalse(VoiceLanguages.isEnglish("eng"))
        assertFalse(VoiceLanguages.isEnglish("fil"))
    }

    private fun pack(
        id: String,
        kind: String,
        languages: List<String>,
        engine: String = VoiceEngines.NEMO_TRANSDUCER,
    ) = InstalledPack(
        manifest = PackManifest(
            id = id,
            kind = kind,
            name = id,
            version = 1,
            languages = languages,
            engine = engine,
            license = "CC-BY-4.0",
            files = emptyList(),
        ),
        dir = File("."),
        sizeBytes = 0,
    )

    private val parakeet = pack("voice-parakeet-en", "voice", listOf("en"))
    private val otherEnglish = pack("voice-other-en", "voice", listOf("en-GB"))
    private val hindiVoice = pack("voice-hi", "voice", listOf("hi"))
    private val translation = pack("translate-en-es", "translation", listOf("en", "es"), engine = "opus-mt-onnx")
    private val all = listOf(translation, hindiVoice, parakeet, otherEnglish)

    private fun resolve(packId: String, language: String?, installed: List<InstalledPack> = all) = resolveVoicePack(
        packId = packId,
        language = language,
        open = { id -> installed.firstOrNull { it.manifest.id == id } },
        list = { installed },
    )

    @Test
    fun englishUsesTheFirstEnglishVoicePack() {
        assertSame(parakeet, resolve("", "en"))
        assertSame(parakeet, resolve("", "en-GB"))
    }

    @Test
    fun namedEnglishPackWins() {
        assertSame(otherEnglish, resolve("voice-other-en", "en"))
    }

    @Test
    fun aNamedPackThatIsNotAnEnglishVoicePackFallsBack() {
        assertSame(parakeet, resolve("translate-en-es", "en"))
        assertSame(parakeet, resolve("voice-hi", "en"))
        // A deleted pack, or an old setting such as the removed Whisper pack, must not mean "no model".
        assertSame(parakeet, resolve("voice-whisper-base", "en"))
    }

    @Test
    fun voiceIsEnglishOnly() {
        assertNull(resolve("", "hi"))
        assertNull(resolve("voice-hi", "hi"))
        assertNull(resolve("voice-parakeet-en", "pt-BR"))
        assertNull(resolve("", null))
        assertNull(resolve("", ""))
    }

    @Test
    fun noEnglishVoicePackMeansNoModel() {
        assertNull(resolve("", "en", emptyList()))
        assertNull(resolve("", "en", listOf(translation, hindiVoice)))
        assertNull(resolve("translate-en-es", "en", listOf(translation)))
    }
}
