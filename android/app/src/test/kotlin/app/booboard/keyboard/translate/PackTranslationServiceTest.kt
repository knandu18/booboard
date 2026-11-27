// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.translate

import app.booboard.keyboard.packs.PackStore
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.nio.file.Files
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class PackTranslationServiceTest {
    private val keys: KeyPair = KeyPairGenerator.getInstance("EC")
        .apply { initialize(ECGenParameterSpec("secp256r1")) }
        .generateKeyPair()

    @Test
    fun reportsNoPackWhenNothingIsInstalled() {
        val service = PackTranslationService(PackStore(Files.createTempDirectory("packs").toFile(), listOf(keys.public)))
        expectCode("no_pack") { service.translate("Hello", "en", "es") }
        service.release()
    }

    @Test
    fun aPackOnlyCoversItsOwnDirection() {
        val store = PackStore(Files.createTempDirectory("packs").toFile(), listOf(keys.public))
        store.install(ByteArrayInputStream(signedPack("translate-en-pt", listOf("en", "pt"))))
        // The installed model translates English to Portuguese; Portuguese to English is a different model.
        expectCode("no_pack") { PackTranslationService(store).translate("Onde fica", "pt", "en") }
        expectCode("no_pack") { PackTranslationService(store).translate("Hello", "en", "es") }
    }

    @Test
    fun brazilianAndEuropeanPortugueseUseThePortugueseModels() {
        val store = PackStore(Files.createTempDirectory("packs").toFile(), listOf(keys.public))
        store.install(ByteArrayInputStream(signedPack("translate-en-pt", listOf("en", "pt"))))
        // The pack is found (the fake model then fails to load, which is not "no_pack").
        for (target in listOf("pt-BR", "pt-PT")) {
            try {
                PackTranslationService(store).translate("Hello", "en", target)
                fail("the fake model cannot run")
            } catch (e: TranslationException) {
                assertNotEquals("no_pack", e.code)
            } catch (e: Exception) {
                // Expected: the placeholder files are not a model.
            }
        }
    }

    @Test
    fun mapsRegionalPortugueseToThePack() {
        assertEquals("pt", packLanguage("pt-BR"))
        assertEquals("pt", packLanguage("pt-PT"))
        assertEquals("es", packLanguage("es"))
    }

    @Test
    fun splitsSentencesAtPunctuationAndLines() {
        assertEquals(
            listOf("Hello there.", "How are you?", "¿Dónde?", "New line"),
            splitSentences("Hello there.  How are you? ¿Dónde?\nNew line"),
        )
        assertEquals(emptyList<String>(), splitSentences("  \n "))
    }

    @Test
    fun cutsLongRunsAtWordBoundaries() {
        val long = List(120) { "word$it" }.joinToString(" ")
        val parts = splitSentences(long)
        assertTrue(parts.size > 1)
        assertTrue(parts.all { it.length <= 240 })
        assertEquals(long, parts.joinToString(" "))
    }

    private fun expectCode(code: String, block: () -> Unit) {
        try {
            block()
            fail("expected $code")
        } catch (e: TranslationException) {
            assertEquals(code, e.code)
        }
    }

    /** A signed `.boopack` with placeholder files, for pack lookup tests (never loaded as a model). */
    private fun signedPack(id: String, languages: List<String>): ByteArray {
        val files = linkedMapOf(
            "model/encoder.onnx" to byteArrayOf(1, 2, 3),
            "model/config.json" to """{"pad_id":0,"eos_id":0,"unk_id":1,"decoder_start_id":0,"target_token":null}""".toByteArray(),
        )
        val list = files.entries.joinToString(",") { (path, data) ->
            """{"path":"$path","size":${data.size},"sha256":"${sha256(data)}"}"""
        }
        val langs = languages.joinToString(",") { "\"$it\"" }
        val manifest = (
            """{"id":"$id","kind":"translation","name":"test","version":1,"languages":[$langs],""" +
                """"engine":"opus-mt-onnx","license":"CC-BY-4.0","files":[$list]}"""
            ).toByteArray()
        val sig = Signature.getInstance("SHA256withECDSA").run {
            initSign(keys.private)
            update(manifest)
            sign()
        }
        val out = ByteArrayOutputStream()
        DataOutputStream(out).apply {
            write(PackStore.MAGIC)
            writeInt(PackStore.FORMAT_VERSION)
            writeInt(manifest.size)
            write(manifest)
            writeInt(sig.size)
            write(sig)
            files.values.forEach { write(it) }
        }
        return out.toByteArray()
    }

    private fun sha256(b: ByteArray) = MessageDigest.getInstance("SHA-256").digest(b).joinToString("") { "%02x".format(it) }
}
