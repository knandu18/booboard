// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.io.File
import java.io.InputStream
import java.nio.file.Files
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

class PackSourceTest {
    private lateinit var root: File
    private val keys: KeyPair = newKeys()

    @Before
    fun setUp() {
        root = Files.createTempDirectory("packs").toFile()
    }

    @Test
    fun aDeliveredPackInstallsThroughTheSamePathAsAnImport() {
        val source = FakeStoreSource(delivered = mapOf("translate-en-es" to pack()))
        val store = PackStore(root, listOf(keys.public))
        val installed = DeliveredPacks.install(source, store, "translate-en-es")
        assertEquals("translate-en-es", installed?.manifest?.id)
        assertEquals(PackStore.keyId(keys.public), installed?.signerKeyId)
        assertEquals(listOf("translate-en-es"), source.released)
        assertTrue(store.open("translate-en-es") != null)
    }

    @Test
    fun aPackThatIsNotDeliveredYetChangesNothing() {
        val source = FakeStoreSource(delivered = emptyMap())
        val store = PackStore(root, listOf(keys.public))
        assertNull(DeliveredPacks.install(source, store, "translate-en-es"))
        assertTrue(source.released.isEmpty())
        assertTrue(store.list().isEmpty())
    }

    @Test
    fun aDeliveredCopyThatFailsVerificationIsRejectedAndKeptInTheStore() {
        val bytes = pack()
        bytes[bytes.size - 1] = (bytes[bytes.size - 1].toInt() xor 0x01).toByte()
        val source = FakeStoreSource(delivered = mapOf("translate-en-es" to bytes))
        val store = PackStore(root, listOf(keys.public))
        try {
            DeliveredPacks.install(source, store, "translate-en-es")
            fail("a damaged delivered pack must not install")
        } catch (e: PackException) {
            assertEquals("bad_signature", e.code)
        }
        assertTrue(source.released.isEmpty())
        assertTrue(store.list().isEmpty())
        assertTrue("staging files were left behind", root.listFiles()!!.isEmpty())
    }

    @Test
    fun aDeliveredPackFromAnUntrustedKeyIsRejected() {
        val other = newKeys()
        val source = FakeStoreSource(delivered = mapOf("translate-en-es" to pack(signer = other)))
        val store = PackStore(root, listOf(keys.public))
        expectCode("bad_signature") { DeliveredPacks.install(source, store, "translate-en-es") }
        assertTrue(source.released.isEmpty())
    }

    @Test
    fun importOnlySourcesOfferNothingAndDeliverNothing() {
        val source = FilePackSource()
        assertFalse(source.storeDelivered)
        assertTrue(source.offers().isEmpty())
        assertNull(source.openDelivered("translate-en-es"))
        assertNull(DeliveredPacks.install(source, PackStore(root, listOf(keys.public)), "translate-en-es"))
    }

    @Test
    fun theCatalogCoversEachStorePackOnceWithAValidAssetPackName() {
        val entries = StoreCatalog.entries
        assertEquals(entries.map { it.id }.distinct(), entries.map { it.id })
        assertEquals(entries.map { it.packName }.distinct(), entries.map { it.packName })
        for (e in entries) {
            assertTrue("bad asset pack name ${e.packName}", Regex("[a-z][a-z0-9_]*").matches(e.packName))
            assertTrue(PackStore.ID_RE.matches(e.id))
            assertTrue(e.expectedBytes > 0)
        }
        assertEquals("pack_dict_zh", StoreCatalog.byId("dict-zh-rime-ice")?.packName)
        assertNull(StoreCatalog.byId("no-such-pack"))
    }

    // ---- helpers -------------------------------------------------------------------

    /** Stands in for the Play source: delivered copies are byte arrays, release calls are recorded. */
    private class FakeStoreSource(private val delivered: Map<String, ByteArray>) : PackSource {
        val released = mutableListOf<String>()
        override val storeDelivered: Boolean get() = true
        override fun offers(): List<PackOffer> = emptyList()
        override fun request(id: String) = Unit
        override fun openDelivered(id: String): InputStream? = delivered[id]?.let { ByteArrayInputStream(it) }
        override fun release(id: String) {
            released += id
        }
    }

    private fun expectCode(code: String, block: () -> Unit) {
        try {
            block()
            fail("expected $code")
        } catch (e: PackException) {
            assertEquals(code, e.code)
        }
    }

    private fun pack(signer: KeyPair = keys): ByteArray {
        val data = byteArrayOf(1, 2, 3)
        val sha = MessageDigest.getInstance("SHA-256").digest(data).joinToString("") { "%02x".format(it) }
        val manifest = (
            """{"id":"translate-en-es","kind":"translation","name":"English → Spanish","version":1,""" +
                """"languages":["en","es"],"engine":"test","license":"CC0-1.0",""" +
                """"files":[{"path":"a.bin","size":3,"sha256":"$sha"}]}"""
            ).toByteArray()
        val sig = Signature.getInstance("SHA256withECDSA").run {
            initSign(signer.private)
            update(manifest)
            sign()
        }
        val out = ByteArrayOutputStream()
        DataOutputStream(out).apply {
            write("BOOPACK1".toByteArray(Charsets.US_ASCII))
            writeInt(PackStore.FORMAT_VERSION)
            writeInt(manifest.size)
            write(manifest)
            writeInt(sig.size)
            write(sig)
            write(data)
        }
        return out.toByteArray()
    }

    private companion object {
        fun newKeys(): KeyPair =
            KeyPairGenerator.getInstance("EC").apply { initialize(ECGenParameterSpec("secp256r1")) }.generateKeyPair()
    }
}
