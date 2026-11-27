// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.security.backup

import java.nio.ByteBuffer
import java.security.GeneralSecurityException
import java.security.SecureRandom
import javax.crypto.BadPaddingException
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/**
 * Failure with a code Dart can read. [code] is one of the constants on the companion; messages
 * never contain backup content, names or passphrases.
 */
class BackupException(val code: String, message: String) : Exception(message) {
    companion object {
        const val UNSUPPORTED_VERSION = "unsupported_version"
        const val TOO_LARGE = "too_large"
        const val BUSY = "busy"
        const val IO = "backup_io"
    }
}

/**
 * The .boobackup file format, version 1. Integers are big-endian.
 *
 * ```
 * offset  size  field
 * 0       6     magic "BOOBAK"
 * 6       1     format version (1)
 * 7       1     KDF id (1 = PBKDF2-HMAC-SHA256)
 * 8       4     PBKDF2 iteration count
 * 12      16    random salt
 * 28      12    random AES-GCM IV
 * 40      n     AES-256-GCM ciphertext, then the 16-byte tag
 * ```
 *
 * The 40-byte header is the GCM additional authenticated data, so changing any header byte makes
 * decryption fail. The 256-bit key is derived from the passphrase with PBKDF2-HMAC-SHA256.
 */
internal object BackupCrypto {
    const val FORMAT_VERSION = 1
    const val DEFAULT_ITERATIONS = 600_000

    private const val MAGIC = "BOOBAK"
    private const val KDF_PBKDF2_SHA256 = 1
    private const val MAX_ITERATIONS = 2_000_000
    private const val SALT_BYTES = 16
    private const val IV_BYTES = 12
    private const val KEY_BITS = 256
    private const val TAG_BITS = 128
    private const val TAG_BYTES = TAG_BITS / 8
    private const val HEADER_BYTES = 6 + 1 + 1 + 4 + SALT_BYTES + IV_BYTES
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val KDF_ALGORITHM = "PBKDF2WithHmacSHA256"

    private val magicBytes = MAGIC.toByteArray(Charsets.US_ASCII)
    private val random = SecureRandom()

    /** Encrypts [plain] with a fresh salt and IV at [DEFAULT_ITERATIONS]. */
    fun seal(plain: ByteArray, passphrase: String): ByteArray = sealWith(
        plain = plain,
        passphrase = passphrase,
        salt = ByteArray(SALT_BYTES).also(random::nextBytes),
        iv = ByteArray(IV_BYTES).also(random::nextBytes),
        iterations = DEFAULT_ITERATIONS,
    )

    /** Same as [seal] with caller-chosen salt, IV and iteration count (tests use a small count). */
    internal fun sealWith(
        plain: ByteArray,
        passphrase: String,
        salt: ByteArray,
        iv: ByteArray,
        iterations: Int,
    ): ByteArray {
        require(passphrase.isNotEmpty()) { "passphrase must not be empty" }
        require(salt.size == SALT_BYTES && iv.size == IV_BYTES) { "bad salt or IV size" }
        require(iterations in 1..MAX_ITERATIONS) { "bad iteration count" }
        val header = header(iterations, salt, iv)
        val key = deriveKey(passphrase, salt, iterations)
        try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, iv))
            cipher.updateAAD(header)
            return header + cipher.doFinal(plain)
        } finally {
            key.fill(0)
        }
    }

    /**
     * Decrypts a .boobackup file. Returns null for a wrong passphrase, a damaged file or a file
     * that is not a backup. Throws [BackupException] (code `unsupported_version`) for a newer format.
     */
    fun open(sealed: ByteArray, passphrase: String): ByteArray? {
        if (sealed.size < HEADER_BYTES + TAG_BYTES) return null
        if (!sealed.copyOfRange(0, magicBytes.size).contentEquals(magicBytes)) return null
        val version = sealed[6].toInt() and 0xFF
        if (version > FORMAT_VERSION) {
            throw BackupException(BackupException.UNSUPPORTED_VERSION, "backup format $version is newer than this app")
        }
        if (version != FORMAT_VERSION) return null
        if (sealed[7].toInt() != KDF_PBKDF2_SHA256) return null
        val iterations = ByteBuffer.wrap(sealed, 8, 4).int
        if (iterations !in 1..MAX_ITERATIONS) return null

        val header = sealed.copyOfRange(0, HEADER_BYTES)
        val salt = sealed.copyOfRange(12, 12 + SALT_BYTES)
        val iv = sealed.copyOfRange(12 + SALT_BYTES, HEADER_BYTES)
        val body = sealed.copyOfRange(HEADER_BYTES, sealed.size)
        val key = deriveKey(passphrase, salt, iterations)
        try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, iv))
            cipher.updateAAD(header)
            return cipher.doFinal(body)
        } catch (e: BadPaddingException) {
            // AEADBadTagException: wrong passphrase or tampered data.
            return null
        } catch (e: GeneralSecurityException) {
            return null
        } finally {
            key.fill(0)
        }
    }

    private fun header(iterations: Int, salt: ByteArray, iv: ByteArray): ByteArray =
        ByteBuffer.allocate(HEADER_BYTES)
            .put(magicBytes)
            .put(FORMAT_VERSION.toByte())
            .put(KDF_PBKDF2_SHA256.toByte())
            .putInt(iterations)
            .put(salt)
            .put(iv)
            .array()

    /** Returns the raw 256-bit key. The caller zeroes it. The passphrase chars are zeroed here. */
    private fun deriveKey(passphrase: String, salt: ByteArray, iterations: Int): ByteArray {
        val chars = passphrase.toCharArray()
        val spec = PBEKeySpec(chars, salt, iterations, KEY_BITS)
        try {
            return SecretKeyFactory.getInstance(KDF_ALGORITHM).generateSecret(spec).encoded
        } finally {
            spec.clearPassword()
            chars.fill('\u0000')
        }
    }

    private operator fun ByteArray.plus(other: ByteArray): ByteArray {
        val out = copyOf(size + other.size)
        other.copyInto(out, size)
        return out
    }
}
