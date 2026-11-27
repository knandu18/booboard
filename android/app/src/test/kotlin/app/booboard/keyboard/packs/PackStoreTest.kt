// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.io.File
import java.nio.file.Files
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

class PackStoreTest {
    private lateinit var root: File
    private val keys = newKeys()
    private val other = newKeys()
    private val release = newKeys()

    @Before
    fun setUp() {
        root = Files.createTempDirectory("packs").toFile()
    }

    @Test
    fun installsListsAndDeletes() {
        val store = PackStore(root, listOf(keys.public))
        val files = mapOf("model/a.onnx" to byteArrayOf(1, 2, 3), "tokens.txt" to "hi".toByteArray())
        val installed = store.install(ByteArrayInputStream(pack(files)))
        assertEquals("translate-en-es", installed.manifest.id)
        assertEquals(listOf("en", "es"), installed.manifest.languages)
        assertArrayEquals(byteArrayOf(1, 2, 3), File(store.dir("translate-en-es"), "model/a.onnx").readBytes())
        assertEquals(1, store.list().size)
        assertEquals("translate-en-es", store.find("translation", listOf("en", "es"))?.manifest?.id)
        store.delete("translate-en-es")
        assertTrue(store.list().isEmpty())
    }

    @Test
    fun replacesSameId() {
        val store = PackStore(root, listOf(keys.public))
        store.install(ByteArrayInputStream(pack(mapOf("a.bin" to byteArrayOf(1)))))
        store.install(ByteArrayInputStream(pack(mapOf("b.bin" to byteArrayOf(2)), version = 2)))
        val p = store.open("translate-en-es")!!
        assertEquals(2, p.manifest.version)
        assertTrue(!File(p.dir, "a.bin").exists())
        assertEquals(1, root.listFiles()!!.size)
    }

    // ---- key rotation -------------------------------------------------------------

    @Test
    fun packsFromEveryTrustedKeyInstallAndNameTheirSigner() {
        val store = PackStore(root, listOf(release.public, keys.public))
        val fromRelease = store.install(ByteArrayInputStream(pack(mapOf("a" to byteArrayOf(1)), signer = release)))
        assertEquals(PackStore.keyId(release.public), fromRelease.signerKeyId)
        val fromDev = store.install(ByteArrayInputStream(pack(mapOf("b" to byteArrayOf(2)), id = "dict-zh-rime", kind = "dictionary", languages = """["zh"]""", signer = keys)))
        assertEquals(PackStore.keyId(keys.public), fromDev.signerKeyId)
        assertEquals(2, store.list().size)
        assertEquals(2, store.list().map { it.signerKeyId }.toSet().size)
    }

    @Test
    fun keyIdIsSixteenHexDigitsOfSha256OverTheKey() {
        val id = PackStore.keyId(keys.public)
        assertEquals(16, id.length)
        assertTrue(id.matches(Regex("[0-9a-f]{16}")))
        val expected = MessageDigest.getInstance("SHA-256").digest(keys.public.encoded).copyOf(8).toHex()
        assertEquals(expected, id)
        assertFalse(id == PackStore.keyId(other.public))
    }

    @Test
    fun aPackFromAnUnknownKeyIsRejectedEvenWhenOtherKeysAreTrusted() {
        val store = PackStore(root, listOf(release.public, keys.public))
        expect("bad_signature") {
            store.install(ByteArrayInputStream(pack(mapOf("a" to byteArrayOf(1)), signer = other)))
        }
        assertNothingInstalled()
    }

    @Test
    fun aKeyNotListedIsNotTrustedEvenIfItIsAValidKey() {
        // The dev key is absent from a release trust list: packs it signed must not install.
        val store = PackStore(root, listOf(release.public))
        expect("bad_signature") { store.install(ByteArrayInputStream(pack(mapOf("a" to byteArrayOf(1)), signer = keys))) }
        assertNothingInstalled()
    }

    // ---- rejected packs leave nothing behind -----------------------------------------

    @Test
    fun rejectsUntrustedSignature() = expect("bad_signature") {
        PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(pack(mapOf("a" to byteArrayOf(1)), signer = other)))
    }

    @Test
    fun rejectsTamperedFile() {
        val bytes = pack(mapOf("a.bin" to byteArrayOf(1, 2, 3)))
        bytes[bytes.size - 1] = 9
        expect("bad_signature") { PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(bytes)) }
        assertNothingInstalled()
    }

    @Test
    fun rejectsAFlippedBitInTheManifest() {
        val bytes = pack(mapOf("a.bin" to byteArrayOf(1, 2, 3)))
        // Header is magic (8) + version (4) + manifest length (4); flip one bit of the first manifest byte.
        bytes[16] = (bytes[16].toInt() xor 0x01).toByte()
        expect("bad_signature") { PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(bytes)) }
        assertNothingInstalled()
    }

    @Test
    fun rejectsTruncatedAndTrailingData() {
        val bytes = pack(mapOf("a.bin" to byteArrayOf(1, 2, 3)))
        expect("bad_format") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(bytes.copyOf(bytes.size - 1)))
        }
        expect("bad_format") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(bytes + byteArrayOf(0)))
        }
        assertNothingInstalled()
    }

    @Test
    fun rejectsAHeaderThatEndsEarly() {
        val bytes = pack(mapOf("a.bin" to byteArrayOf(1)))
        expect("bad_format") { PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(bytes.copyOf(12))) }
        assertNothingInstalled()
    }

    @Test
    fun rejectsPathEscapes() {
        for (path in listOf("../x", "a/../../x", "/abs", "manifest.json", "a//b")) {
            expect("bad_format") {
                PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(pack(mapOf(path to byteArrayOf(1)))))
            }
        }
        assertNothingInstalled()
    }

    @Test
    fun rejectsADuplicateFileName() {
        val entry = """{"path":"a.bin","size":1,"sha256":"${sha256(byteArrayOf(1))}"}"""
        val manifest = manifestJson(files = "$entry,$entry")
        expect("bad_format") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(packRaw(manifest, listOf(byteArrayOf(1), byteArrayOf(1)))))
        }
        assertNothingInstalled()
    }

    @Test
    fun rejectsAFileNameThatIsAFolderOfAnotherFile() {
        val a = """{"path":"a","size":1,"sha256":"${sha256(byteArrayOf(1))}"}"""
        val b = """{"path":"a/b","size":1,"sha256":"${sha256(byteArrayOf(2))}"}"""
        val manifest = manifestJson(files = "$a,$b")
        expect("bad_format") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(packRaw(manifest, listOf(byteArrayOf(1), byteArrayOf(2)))))
        }
        assertNothingInstalled()
    }

    @Test
    fun rejectsASizeLargerThanTheData() {
        val entry = """{"path":"a.bin","size":10,"sha256":"${sha256(byteArrayOf(1, 2, 3))}"}"""
        expect("bad_format") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(packRaw(manifestJson(files = entry), listOf(byteArrayOf(1, 2, 3)))))
        }
        assertNothingInstalled()
    }

    @Test
    fun rejectsMoreThanSixtyFourFiles() {
        val entries = (0..PackStore.MAX_FILES).map { """{"path":"f$it.bin","size":1,"sha256":"${sha256(byteArrayOf(1))}"}""" }
        val bodies = List(entries.size) { byteArrayOf(1) }
        expect("bad_format") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(packRaw(manifestJson(files = entries.joinToString(",")), bodies)))
        }
        assertNothingInstalled()
    }

    @Test
    fun rejectsWrongMagicVersionAndSize() {
        expect("bad_format") { PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(ByteArray(40))) }
        val v2 = pack(mapOf("a" to byteArrayOf(1)))
        v2[11] = 2
        expect("unsupported_version") { PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(v2)) }
        expect("too_large") {
            PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(pack(mapOf("a" to ByteArray(10)))), 5)
        }
        assertNothingInstalled()
    }

    @Test
    fun installsDictionaryPacks() {
        val store = PackStore(root, listOf(keys.public))
        val bytes = pack(mapOf("dict/base.bin" to byteArrayOf(7)), id = "dict-zh-rime", kind = "dictionary", languages = """["zh"]""")
        val installed = store.install(ByteArrayInputStream(bytes))
        assertEquals(PackManifest.KIND_DICTIONARY, installed.manifest.kind)
        assertArrayEquals(byteArrayOf(7), File(store.dir("dict-zh-rime"), "dict/base.bin").readBytes())
        assertEquals("dict-zh-rime", store.find("dictionary", listOf("zh"))?.manifest?.id)
    }

    @Test
    fun installsImagePacksAndFindsTheirModelFiles() {
        val store = PackStore(root, listOf(keys.public))
        val bytes = pack(
            mapOf("model/model.gguf" to byteArrayOf(1, 2), "model/taesd.safetensors" to byteArrayOf(3)),
            id = "images-lcm-dreamshaper-v7",
            kind = "image",
            languages = """["en"]""",
        )
        val installed = store.install(ByteArrayInputStream(bytes))
        assertEquals(PackManifest.KIND_IMAGE, installed.manifest.kind)
        assertEquals("images-lcm-dreamshaper-v7", store.find("image", emptyList())?.manifest?.id)
        assertEquals(null, store.find("voice", emptyList()))
    }

    @Test
    fun rejectsUnknownKind() = expect("bad_format") {
        PackStore(root, listOf(keys.public)).install(ByteArrayInputStream(pack(mapOf("a" to byteArrayOf(1)), kind = "code")))
    }

    @Test
    fun openRejectsEditedManifest() {
        val store = PackStore(root, listOf(keys.public))
        val p = store.install(ByteArrayInputStream(pack(mapOf("a" to byteArrayOf(1)))))
        File(p.dir, PackStore.MANIFEST).appendText(" ")
        assertNull(store.open("translate-en-es"))
    }

    // ---- re-checking installed packs ----------------------------------------------

    @Test
    fun checkPassesForAnIntactPack() {
        val store = PackStore(root, listOf(keys.public))
        store.install(ByteArrayInputStream(pack(mapOf("a.bin" to byteArrayOf(1, 2), "m/b.bin" to byteArrayOf(3)))))
        val check = store.check("translate-en-es")!!
        assertTrue(check.ok)
        assertEquals(0, check.missingFiles)
        assertEquals(0, check.damagedFiles)
    }

    @Test
    fun checkCountsDamagedAndMissingFiles() {
        val store = PackStore(root, listOf(keys.public))
        val p = store.install(ByteArrayInputStream(pack(mapOf("a.bin" to byteArrayOf(1, 2), "b.bin" to byteArrayOf(3, 4)))))
        File(p.dir, "a.bin").writeBytes(byteArrayOf(9, 9)) // same size, different content
        File(p.dir, "b.bin").delete()
        val check = store.check("translate-en-es")!!
        assertFalse(check.ok)
        assertTrue(check.manifestOk)
        assertEquals(1, check.damagedFiles)
        assertEquals(1, check.missingFiles)
    }

    @Test
    fun checkReportsAnEditedManifestAndUnknownIds() {
        val store = PackStore(root, listOf(keys.public))
        val p = store.install(ByteArrayInputStream(pack(mapOf("a.bin" to byteArrayOf(1)))))
        File(p.dir, PackStore.MANIFEST).appendText(" ")
        val check = store.check("translate-en-es")!!
        assertFalse(check.manifestOk)
        assertFalse(check.ok)
        assertNull(store.check("no-such-pack"))
        assertNull(store.check("../escape"))
        assertEquals(listOf("translate-en-es"), store.checkAll().map { it.id })
    }

    // ---- helpers -------------------------------------------------------------------

    private fun assertNothingInstalled() {
        assertTrue("staging or installed files were left behind", root.listFiles()!!.isEmpty())
    }

    private fun expect(code: String, block: () -> Unit) {
        try {
            block()
            fail("expected $code")
        } catch (e: PackException) {
            assertEquals(code, e.code)
        }
    }

    private fun pack(
        files: Map<String, ByteArray>,
        version: Int = 1,
        signer: KeyPair = keys,
        id: String = "translate-en-es",
        kind: String = "translation",
        languages: String = """["en","es"]""",
    ): ByteArray {
        val list = files.entries.joinToString(",") { (path, data) ->
            """{"path":"$path","size":${data.size},"sha256":"${sha256(data)}"}"""
        }
        val manifest = manifestJson(files = list, version = version, id = id, kind = kind, languages = languages)
        return packRaw(manifest, files.values.toList(), signer)
    }

    private fun manifestJson(
        files: String,
        version: Int = 1,
        id: String = "translate-en-es",
        kind: String = "translation",
        languages: String = """["en","es"]""",
    ): ByteArray = ("""{"id":"$id","kind":"$kind","name":"English → Spanish",""" +
        """"version":$version,"languages":$languages,"engine":"test","license":"CC0-1.0","files":[$files]}""")
        .toByteArray()

    /** A `.boopack` whose manifest and bodies are given as they are, signed by [signer]. */
    private fun packRaw(manifest: ByteArray, bodies: List<ByteArray>, signer: KeyPair = keys): ByteArray {
        val sig = Signature.getInstance("SHA256withECDSA").run {
            initSign(signer.private)
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
            bodies.forEach { write(it) }
        }
        return out.toByteArray()
    }

    private fun sha256(b: ByteArray) = MessageDigest.getInstance("SHA-256").digest(b).toHex()

    private companion object {
        fun newKeys(): KeyPair =
            KeyPairGenerator.getInstance("EC").apply { initialize(ECGenParameterSpec("secp256r1")) }.generateKeyPair()
    }
}
