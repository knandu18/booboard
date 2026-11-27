// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.security.backup

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test

class BackupCryptoTest {

    private val plain = "BooBoard backup test vector".toByteArray(Charsets.UTF_8)
    private val passphrase = "correct horse battery staple"
    private val salt = ByteArray(16) { it.toByte() }
    private val iv = ByteArray(12) { (0x10 + it).toByte() }
    private val iterations = 1000

    /** Header is 40 bytes; the body follows. Offsets: magic 0, version 6, kdf 7, iterations 8, salt 12, iv 28. */
    private fun sealSmall(): ByteArray = BackupCrypto.sealWith(plain, passphrase, salt, iv, iterations)

    @Test
    fun matchesReferenceTestVector() {
        // Produced independently with Node's crypto module (PBKDF2-SHA256 + AES-256-GCM, AAD = header).
        val expected = hex(
            "424f4f42414b0101000003e8000102030405060708090a0b0c0d0e0f" +
                "101112131415161718191a1b" +
                "5e88de6108a78fc04a0b511eb1e843d3c14fee670081b794fe46a930c773839bae41222a0902e0ff44b81b",
        )
        assertArrayEquals(expected, sealSmall())
        assertArrayEquals(plain, BackupCrypto.open(expected, passphrase))
    }

    @Test
    fun roundTripWithDefaultIterations() {
        val sealed = BackupCrypto.seal(plain, passphrase)
        // Header records the production iteration count: 600000 = 0x000927c0.
        assertEquals(0x00, sealed[8].toInt())
        assertEquals(0x09, sealed[9].toInt())
        assertEquals(0x27, sealed[10].toInt())
        assertEquals(0xC0, sealed[11].toInt() and 0xFF)
        assertArrayEquals(plain, BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun wrongPassphraseReturnsNull() {
        assertNull(BackupCrypto.open(sealSmall(), "wrong passphrase"))
    }

    @Test
    fun tamperedCiphertextReturnsNull() {
        val sealed = sealSmall()
        sealed[sealed.size - 20] = (sealed[sealed.size - 20].toInt() xor 0x01).toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun tamperedTagReturnsNull() {
        val sealed = sealSmall()
        sealed[sealed.size - 1] = (sealed[sealed.size - 1].toInt() xor 0x80).toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun changedSaltHeaderReturnsNull() {
        val sealed = sealSmall()
        sealed[12] = (sealed[12].toInt() xor 0x01).toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun changedIvHeaderReturnsNull() {
        val sealed = sealSmall()
        sealed[28] = (sealed[28].toInt() xor 0x01).toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun changedIterationCountHeaderReturnsNull() {
        val sealed = sealSmall()
        // 1000 -> 1001: a different key, so decryption fails rather than succeeding.
        sealed[11] = (sealed[11].toInt() xor 0x01).toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun changedKdfIdReturnsNull() {
        val sealed = sealSmall()
        sealed[7] = 2
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun badMagicReturnsNull() {
        val sealed = sealSmall()
        sealed[0] = 'X'.code.toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun truncatedFileReturnsNull() {
        assertNull(BackupCrypto.open(sealSmall().copyOf(40 + 15), passphrase))
        assertNull(BackupCrypto.open(ByteArray(3), passphrase))
    }

    @Test
    fun outOfRangeIterationCountReturnsNull() {
        val sealed = sealSmall()
        // 0x7fffffff iterations would hang the device: rejected before any key derivation.
        sealed[8] = 0x7f
        sealed[9] = 0xff.toByte()
        sealed[10] = 0xff.toByte()
        sealed[11] = 0xff.toByte()
        assertNull(BackupCrypto.open(sealed, passphrase))
    }

    @Test
    fun newerFormatVersionThrowsUnsupportedVersion() {
        val sealed = sealSmall()
        sealed[6] = 2
        val e = assertThrows(BackupException::class.java) { BackupCrypto.open(sealed, passphrase) }
        assertEquals(BackupException.UNSUPPORTED_VERSION, e.code)
    }

    @Test
    fun emptyPassphraseIsRejectedWhenSealing() {
        assertThrows(IllegalArgumentException::class.java) {
            BackupCrypto.sealWith(plain, "", salt, iv, iterations)
        }
    }

    @Test
    fun emptyPlainTextRoundTrips() {
        val sealed = BackupCrypto.sealWith(ByteArray(0), passphrase, salt, iv, iterations)
        assertArrayEquals(ByteArray(0), BackupCrypto.open(sealed, passphrase))
    }

    private fun hex(s: String): ByteArray = ByteArray(s.length / 2) { i ->
        s.substring(i * 2, i * 2 + 2).toInt(16).toByte()
    }
}
