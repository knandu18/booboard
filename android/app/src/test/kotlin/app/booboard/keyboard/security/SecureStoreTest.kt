// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.security

import java.io.File
import java.nio.file.Files
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test

/** Software key provider whose behaviour the tests can flip. */
private class FakeKeys : KeyProvider {
    class Locked : Exception("locked")

    class Invalidated : Exception("invalidated")

    var current: SecretKey = newKey()
    var failure: Exception? = null
    var deleted = 0

    override fun key(): SecretKey {
        failure?.let { throw it }
        return current
    }

    override fun deleteKey() {
        deleted++
        current = newKey()
    }

    override fun classify(error: Throwable): KeyFailure {
        var t: Throwable? = error
        while (t != null) {
            if (t is Locked) return KeyFailure.LOCKED
            if (t is Invalidated) return KeyFailure.INVALIDATED
            t = t.cause
        }
        return KeyFailure.OTHER
    }

    fun newKey(): SecretKey = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()

    /** A view of this provider whose key is usable again as soon as it has been deleted. */
    fun healsOnDelete(): KeyProvider {
        val outer = this
        return object : KeyProvider by outer {
            override fun deleteKey() {
                outer.deleteKey()
                outer.failure = null
            }
        }
    }
}

class SecureStoreTest {
    private lateinit var dir: File
    private lateinit var keys: FakeKeys
    private lateinit var store: SecureStore

    @Before
    fun setUp() {
        dir = Files.createTempDirectory("booboard-secure").toFile()
        keys = FakeKeys()
        store = SecureStore(dir, keys)
    }

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    private fun bytes(s: String) = s.toByteArray(Charsets.UTF_8)

    @Test
    fun roundTrip() {
        store.write("words", bytes("hello"))
        assertArrayEquals(bytes("hello"), store.read("words"))
        store.write("words", bytes("hello again"))
        assertArrayEquals(bytes("hello again"), store.read("words"))
    }

    @Test
    fun blobCopiedOverAnotherNameDoesNotDecrypt() {
        store.write("learned_en", bytes("words"))
        store.write("clipboard", bytes("history"))
        File(dir, "learned_en.bin").copyTo(File(dir, "clipboard.bin"), overwrite = true)
        File(dir, "clipboard.bak").delete()
        assertNull(store.read("clipboard"))
        assertArrayEquals(bytes("words"), store.read("learned_en"))
    }

    @Test
    fun versionOneFilesAreUnreadable() {
        store.write("words", bytes("hello"))
        val file = File(dir, "words.bin")
        val raw = file.readBytes()
        raw[0] = 1 // the old format, without the name binding
        file.writeBytes(raw)
        File(dir, "words.bak").delete()
        assertNull(store.read("words"))
    }

    @Test
    fun missingBlobReadsAsNull() {
        assertNull(store.read("nothing"))
    }

    @Test
    fun emptyBlobRoundTrips() {
        store.write("empty", ByteArray(0))
        assertArrayEquals(ByteArray(0), store.read("empty"))
    }

    @Test
    fun fileFormatIsVersionIvLengthIvCiphertext() {
        val plain = bytes("format check")
        store.write("fmt", plain)
        val raw = File(dir, "fmt.bin").readBytes()
        assertEquals(2, raw[0].toInt())
        assertEquals(12, raw[1].toInt())
        // 2 header bytes + 12 iv + ciphertext (plain length) + 16 byte tag
        assertEquals(2 + 12 + plain.size + 16, raw.size)
        assertFalse(String(raw, Charsets.ISO_8859_1).contains("format check"))
    }

    @Test
    fun ivIsFreshForEveryWrite() {
        store.write("iv", bytes("same"))
        val first = File(dir, "iv.bin").readBytes().copyOfRange(2, 14)
        store.write("iv", bytes("same"))
        val second = File(dir, "iv.bin").readBytes().copyOfRange(2, 14)
        assertFalse(first.contentEquals(second))
    }

    @Test
    fun secondWriteKeepsFirstAsBackupAndLeavesNoTempFile() {
        store.write("a", bytes("one"))
        store.write("a", bytes("two"))
        assertTrue(File(dir, "a.bak").exists())
        assertFalse(File(dir, "a.tmp").exists())
        assertArrayEquals(bytes("two"), store.read("a"))
    }

    @Test
    fun corruptTargetRecoversFromBackup() {
        store.write("a", bytes("one"))
        store.write("a", bytes("two"))
        File(dir, "a.bin").writeBytes(ByteArray(40) { 7 })
        assertArrayEquals(bytes("one"), store.read("a"))
    }

    @Test
    fun missingTargetRecoversFromBackup() {
        store.write("a", bytes("one"))
        store.write("a", bytes("two"))
        File(dir, "a.bin").delete()
        assertArrayEquals(bytes("one"), store.read("a"))
    }

    @Test
    fun tamperedCiphertextIsRejected() {
        store.write("a", bytes("secret"))
        val f = File(dir, "a.bin")
        val raw = f.readBytes()
        raw[raw.size - 1] = (raw[raw.size - 1].toInt() xor 1).toByte()
        f.writeBytes(raw)
        assertNull(store.read("a"))
    }

    @Test
    fun corruptTargetDoesNotReplaceGoodBackup() {
        store.write("a", bytes("one"))
        store.write("a", bytes("two")) // bak = one
        File(dir, "a.bin").writeBytes(ByteArray(40) { 9 })
        store.write("a", bytes("three")) // target was corrupt: bak must stay "one"
        assertArrayEquals(bytes("three"), store.read("a"))
        File(dir, "a.bin").delete()
        assertArrayEquals(bytes("one"), store.read("a"))
    }

    @Test
    fun truncatedAndGarbageFilesReadAsNull() {
        File(dir, "t.bin").writeBytes(byteArrayOf(1))
        assertNull(store.read("t"))
        File(dir, "g.bin").writeBytes(byteArrayOf(2, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3))
        assertNull(store.read("g"))
    }

    @Test
    fun staleTempFilesAreRemovedOnOpen() {
        File(dir, "x.tmp").writeBytes(byteArrayOf(1, 2, 3))
        SecureStore(dir, keys)
        assertFalse(File(dir, "x.tmp").exists())
    }

    @Test
    fun deleteRemovesAllCopies() {
        store.write("a", bytes("one"))
        store.write("a", bytes("two"))
        store.delete("a")
        assertNull(store.read("a"))
        assertFalse(File(dir, "a.bin").exists())
        assertFalse(File(dir, "a.bak").exists())
    }

    @Test
    fun nameValidation() {
        val bad = listOf("", "UPPER", "has space", "a/b", "a\\b", "../x", "x".repeat(65), "a\nb", "é", "a\u0000")
        for (name in bad) {
            try {
                store.write(name, bytes("x"))
                fail("expected rejection of '$name'")
            } catch (e: SecureStoreException) {
                assertEquals(SecureStoreException.INVALID_NAME, e.code)
            }
            try {
                store.read(name)
                fail("expected rejection of '$name' on read")
            } catch (e: SecureStoreException) {
                assertEquals(SecureStoreException.INVALID_NAME, e.code)
            }
        }
        for (name in listOf("a", "a.b-c_d", "0", "x".repeat(64), "learned.words.v1")) {
            store.write(name, bytes("ok"))
            assertArrayEquals(bytes("ok"), store.read(name))
        }
    }

    @Test
    fun wipeAllRemovesBlobsAndDestroysKey() {
        store.write("a", bytes("one"))
        store.write("b", bytes("two"))
        val oldKey = keys.current
        store.wipeAll()
        assertEquals(0, dir.listFiles()!!.size)
        assertEquals(1, keys.deleted)
        assertNotEquals(oldKey, keys.current)
        assertNull(store.read("a"))
    }

    @Test
    fun blobLargerThanCapIsRejected() {
        try {
            store.write("big", ByteArray(SecureStore.MAX_BLOB_BYTES + 1))
            fail("expected TOO_LARGE")
        } catch (e: SecureStoreException) {
            assertEquals(SecureStoreException.TOO_LARGE, e.code)
        }
        assertFalse(File(dir, "big.bin").exists())
    }

    @Test
    fun blobAtCapRoundTrips() {
        val data = ByteArray(SecureStore.MAX_BLOB_BYTES) { (it % 251).toByte() }
        store.write("max", data)
        assertArrayEquals(data, store.read("max"))
    }

    @Test
    fun lockedDeviceReadsNullAndWriteThrows() {
        store.write("a", bytes("one"))
        keys.failure = FakeKeys.Locked()
        assertNull(store.read("a"))
        try {
            store.write("a", bytes("two"))
            fail("expected LOCKED")
        } catch (e: SecureStoreException) {
            assertEquals(SecureStoreException.LOCKED, e.code)
        }
        assertFalse(File(dir, "a.tmp").exists())
        // Nothing was lost: after unlock the old value is back.
        keys.failure = null
        assertArrayEquals(bytes("one"), store.read("a"))
    }

    @Test
    fun strictReadTellsLockedApartFromDamagedAndMissing() {
        store.write("a", bytes("one"))
        store.write("b", bytes("two"))
        // Damage both copies of "b" (the file and its .bak): a strict read says null, not locked.
        File(dir, "b.bin").writeBytes(byteArrayOf(1, 12, 0, 0))
        File(dir, "b.bak").delete()
        assertArrayEquals(bytes("one"), store.readStrict("a"))
        assertNull(store.readStrict("b"))
        assertNull(store.readStrict("missing"))
        keys.failure = FakeKeys.Locked()
        try {
            store.readStrict("a")
            fail("expected LOCKED")
        } catch (e: SecureStoreException) {
            assertEquals(SecureStoreException.LOCKED, e.code)
        }
        assertNull(store.read("a"))
    }

    @Test
    fun invalidatedKeyIsRecreatedOnWriteAndOldDataIsDropped() {
        store.write("a", bytes("one"))
        store.write("b", bytes("old"))
        keys.failure = FakeKeys.Invalidated()
        val s = SecureStore(dir, keys.healsOnDelete())
        s.write("a", bytes("fresh"))
        assertEquals(1, keys.deleted)
        assertArrayEquals(bytes("fresh"), s.read("a"))
        assertNull(s.read("b"))
    }

    @Test
    fun invalidatedKeyOnReadRecreatesKeyAndReturnsNull() {
        store.write("a", bytes("one"))
        keys.failure = FakeKeys.Invalidated()
        val s = SecureStore(dir, keys.healsOnDelete())
        assertNull(s.read("a"))
        assertEquals(1, keys.deleted)
        s.write("a", bytes("again"))
        assertArrayEquals(bytes("again"), s.read("a"))
    }

    @Test
    fun otherKeyFailuresSurfaceAsCryptoErrors() {
        keys.failure = IllegalStateException("boom")
        try {
            store.write("a", bytes("x"))
            fail("expected CRYPTO")
        } catch (e: SecureStoreException) {
            assertEquals(SecureStoreException.CRYPTO, e.code)
        }
        assertNull(store.read("a"))
    }

    @Test
    fun wrongKeyReadsAsNull() {
        store.write("a", bytes("one"))
        keys.current = keys.newKey()
        assertNull(store.read("a"))
    }
}
