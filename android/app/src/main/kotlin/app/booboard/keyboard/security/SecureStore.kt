// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.security

import android.content.Context
import java.io.File
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Why a key operation failed, as far as the store cares. */
enum class KeyFailure {
    /** Device is locked (key needs an unlocked device): try again after unlock. */
    LOCKED,

    /** The key can never be used again (e.g. lock screen removed): it must be recreated. */
    INVALIDATED,

    /** Anything else. */
    OTHER,
}

/** Supplies the AES key. The Android implementation is Keystore-backed; tests use a software key. */
interface KeyProvider {
    /** Returns the existing key, or creates one. Throws when the key is unavailable. */
    fun key(): SecretKey

    /** Destroys the key (no-op when there is none). */
    fun deleteKey()

    /** Maps a failure thrown by [key] or by a [Cipher] built from it. */
    fun classify(error: Throwable): KeyFailure
}

/**
 * Failure that Dart can catch. [code] is one of [LOCKED], [TOO_LARGE], [INVALID_NAME], [CRYPTO],
 * [IO]; the message never contains blob content or names.
 */
class SecureStoreException(val code: String, message: String, cause: Throwable? = null) :
    Exception(message, cause) {
    companion object {
        const val LOCKED = "secure_store_locked"
        const val TOO_LARGE = "secure_store_too_large"
        const val INVALID_NAME = "secure_store_invalid_name"
        const val CRYPTO = "secure_store_crypto"
        const val IO = "secure_store_io"
    }
}

/**
 * Encrypted blob storage for learned words, n-grams, clipboard history and
 * personal shortcuts.
 *
 * - AES-256-GCM with a non-exportable Android Keystore key (StrongBox when available).
 * - Files live in noBackupFilesDir (never backed up; backups are disabled anyway).
 * - Writes are atomic (temp file + rename) and the previous good copy is kept as `.bak`.
 * - A locked device or an invalidated key never crashes: reads return null, writes throw a
 *   [SecureStoreException]. A permanently invalidated key is replaced; the data sealed under
 *   the old key is unreadable by design and is discarded.
 *
 * File format: [1 byte version=2][1 byte iv length][iv][ciphertext+tag]. The blob name is authenticated as
 * AES-GCM additional data, so a file copied over another blob's name does not decrypt. Version 1 (no name
 * binding) is unreadable: no data had shipped when version 2 was introduced.
 *
 * Instances for one directory must be shared: use [SecureStore.get] on Android.
 */
class SecureStore(private val dir: File, private val keys: KeyProvider) {

    init {
        dir.mkdirs()
        // A temp file left by a crash is never valid state.
        dir.listFiles { f -> f.name.endsWith(TMP_SUFFIX) }?.forEach { it.delete() }
    }

    @Synchronized
    fun write(name: String, data: ByteArray) {
        val target = fileFor(name)
        if (data.size > MAX_BLOB_BYTES) {
            throw SecureStoreException(SecureStoreException.TOO_LARGE, "blob exceeds $MAX_BLOB_BYTES bytes")
        }
        val sealed = seal(name, data)
        val tmp = File(dir, name + TMP_SUFFIX)
        try {
            tmp.outputStream().use { out ->
                out.write(sealed)
                out.fd.sync()
            }
            // Keep the previous copy as .bak, but only when it is itself good, so a corrupt
            // target can never replace the last good backup.
            if (target.exists() && decrypt(target, name) != null) {
                move(target, File(dir, name + BAK_SUFFIX))
            }
            move(tmp, target)
        } catch (e: SecureStoreException) {
            tmp.delete()
            throw e
        } catch (e: Exception) {
            tmp.delete()
            throw SecureStoreException(SecureStoreException.IO, "could not write blob", e)
        }
    }

    /** Returns null when the blob is missing, corrupt, or cannot be decrypted right now. */
    @Synchronized
    fun read(name: String): ByteArray? {
        val target = fileFor(name)
        return try {
            decryptOrThrow(target, name) ?: decryptOrThrow(File(dir, name + BAK_SUFFIX), name)
        } catch (e: KeyUnavailable) {
            null
        }
    }

    /**
     * Like [read], but a key that cannot be used right now (locked device, or a key that was just
     * invalidated) throws [SecureStoreException.LOCKED] instead of reading as null. Null still means
     * missing or damaged. Used by the backup restore, which must not merge into data it could not read
     * (SEC-06).
     */
    @Synchronized
    fun readStrict(name: String): ByteArray? {
        val target = fileFor(name)
        return try {
            decryptOrThrow(target, name) ?: decryptOrThrow(File(dir, name + BAK_SUFFIX), name)
        } catch (e: KeyUnavailable) {
            throw SecureStoreException(SecureStoreException.LOCKED, "the encryption key cannot be used right now")
        }
    }

    @Synchronized
    fun delete(name: String) {
        fileFor(name).delete()
        File(dir, name + BAK_SUFFIX).delete()
        File(dir, name + TMP_SUFFIX).delete()
    }

    /** Name, encrypted size (blob plus its last-good backup) and modification time of every blob. */
    @Synchronized
    fun list(): List<BlobInfo> {
        val files = dir.listFiles() ?: return emptyList()
        return files
            .filter { it.name.endsWith(".bin") }
            .map { f ->
                val name = f.name.removeSuffix(".bin")
                val bak = File(dir, name + BAK_SUFFIX)
                BlobInfo(name, f.length() + (if (bak.exists()) bak.length() else 0L), f.lastModified())
            }
            .sortedBy { it.name }
    }

    data class BlobInfo(val name: String, val sizeBytes: Long, val modifiedMillis: Long)

    /** Deletes every blob and destroys the key, so stale copies can never be decrypted. */
    @Synchronized
    fun wipeAll() {
        dir.listFiles()?.forEach { it.delete() }
        runCatching { keys.deleteKey() }
    }

    // ---- crypto -----------------------------------------------------------------

    private class KeyUnavailable : Exception()

    private fun seal(name: String, data: ByteArray): ByteArray {
        return try {
            sealOnce(name, data)
        } catch (e: Exception) {
            when (keys.classify(e)) {
                KeyFailure.LOCKED -> throw SecureStoreException(
                    SecureStoreException.LOCKED, "device is locked; secure storage unavailable", e,
                )
                KeyFailure.INVALIDATED -> {
                    recreateKey()
                    try {
                        sealOnce(name, data)
                    } catch (retry: Exception) {
                        throw SecureStoreException(SecureStoreException.CRYPTO, "encryption failed", retry)
                    }
                }
                KeyFailure.OTHER -> throw SecureStoreException(SecureStoreException.CRYPTO, "encryption failed", e)
            }
        }
    }

    private fun sealOnce(name: String, data: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, keys.key())
        cipher.updateAAD(name.toByteArray(Charsets.US_ASCII)) // binds the ciphertext to its blob name
        val iv = cipher.iv
        val body = cipher.doFinal(data)
        val out = ByteArray(2 + iv.size + body.size)
        out[0] = FORMAT_VERSION.toByte()
        out[1] = iv.size.toByte()
        System.arraycopy(iv, 0, out, 2, iv.size)
        System.arraycopy(body, 0, out, 2 + iv.size, body.size)
        return out
    }

    /** Null on any problem except an unusable key, which throws [KeyUnavailable] (after recovery). */
    private fun decryptOrThrow(file: File, name: String): ByteArray? {
        if (!file.isFile || file.length() > MAX_BLOB_BYTES + OVERHEAD_BYTES) return null
        val bytes = try {
            file.readBytes()
        } catch (e: Exception) {
            return null
        }
        if (bytes.size <= 2 || bytes[0].toInt() != FORMAT_VERSION) return null
        val ivLen = bytes[1].toInt() and 0xFF
        if (ivLen < 12 || bytes.size <= 2 + ivLen) return null
        val iv = bytes.copyOfRange(2, 2 + ivLen)
        return try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, keys.key(), GCMParameterSpec(TAG_BITS, iv))
            cipher.updateAAD(name.toByteArray(Charsets.US_ASCII))
            cipher.doFinal(bytes, 2 + ivLen, bytes.size - 2 - ivLen)
        } catch (e: Exception) {
            when (keys.classify(e)) {
                KeyFailure.LOCKED -> throw KeyUnavailable()
                KeyFailure.INVALIDATED -> {
                    recreateKey()
                    throw KeyUnavailable()
                }
                KeyFailure.OTHER -> null // corrupt file or tag mismatch
            }
        }
    }

    private fun decrypt(file: File, name: String): ByteArray? = try {
        decryptOrThrow(file, name)
    } catch (e: KeyUnavailable) {
        null
    }

    /** The old key is gone for good: drop it, and drop the blobs only it could open. */
    private fun recreateKey() {
        runCatching { keys.deleteKey() }
        dir.listFiles()?.forEach { it.delete() }
    }

    // ---- files ------------------------------------------------------------------

    private fun fileFor(name: String): File {
        if (!NAME.matches(name)) {
            throw SecureStoreException(SecureStoreException.INVALID_NAME, "invalid secure-store name")
        }
        return File(dir, "$name.bin")
    }

    private fun move(from: File, to: File) {
        try {
            Files.move(from.toPath(), to.toPath(), StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
        } catch (e: AtomicMoveNotSupportedException) {
            Files.move(from.toPath(), to.toPath(), StandardCopyOption.REPLACE_EXISTING)
        }
    }

    companion object {
        const val MAX_BLOB_BYTES = 16 * 1024 * 1024
        private const val OVERHEAD_BYTES = 64
        private const val TAG_BITS = 128
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val FORMAT_VERSION = 2
        private const val TMP_SUFFIX = ".tmp"
        private const val BAK_SUFFIX = ".bak"
        private val NAME = Regex("^[a-z0-9_.-]{1,64}$")

        @Volatile
        private var shared: SecureStore? = null

        /** Process-wide instance: the keyboard and settings engines must share one lock. */
        fun get(context: Context): SecureStore = shared ?: synchronized(this) {
            shared ?: SecureStore(
                File(context.applicationContext.noBackupFilesDir, "secure"),
                AndroidKeystoreKeyProvider(context.applicationContext),
            ).also { shared = it }
        }
    }
}
