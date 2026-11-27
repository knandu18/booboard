// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import android.content.Context
import android.content.pm.ApplicationInfo
import java.io.DataInputStream
import java.io.EOFException
import java.io.File
import java.io.InputStream
import java.security.KeyFactory
import java.security.MessageDigest
import java.security.PublicKey
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import java.util.Base64

/**
 * Verified model packs (voice, translation, dictionary), installed under `noBackupFilesDir/packs/<id>/`.
 * Engines (Wave 3-D voice, Wave 3-T translation, Wave 4 dictionaries) read files through [dir].
 *
 * Container (`.boopack`, all integers big-endian):
 * ```
 * "BOOPACK1"  8 bytes magic
 * u32         format version (1)
 * u32         manifest length (<= 64 KiB)
 * bytes       manifest.json (UTF-8)
 * u32         signature length (<= 512)
 * bytes       ECDSA P-256 / SHA-256 signature (DER) over the manifest bytes
 * bytes       the files listed in the manifest, concatenated in manifest order
 * ```
 * Each file's SHA-256 is in the signed manifest, so the whole pack is covered by the signature.
 * A pack is data only: nothing in it is ever executed or loaded as code.
 *
 * Trust: the manifest may be signed by any key in [trustedKeys]. The format has no key field: the
 * signer is the trusted key that verifies, and its id is [keyId] (first 8 bytes of SHA-256 over the
 * DER public key). Old packs signed by the dev key keep installing in debug builds, because the dev
 * key is only in the trusted list there (see [PackKeys]).
 *
 * OWNER: Wave 5-C (pack key rotation). Installation keeps its atomic shape: files go to a temporary
 * folder, are hashed against the signed manifest, and only then renamed into place.
 */
class PackStore(private val root: File, private val trustedKeys: List<PublicKey>) {

    /** Installed packs, sorted by id. Unreadable folders are skipped. */
    @Synchronized
    fun list(): List<InstalledPack> {
        val dirs = root.listFiles { f -> f.isDirectory && !f.name.startsWith(".") } ?: return emptyList()
        return dirs.sortedBy { it.name }.mapNotNull { open(it.name) }
    }

    /** The installed pack [id] with its manifest re-verified, or null. */
    @Synchronized
    fun open(id: String): InstalledPack? {
        if (!ID_RE.matches(id)) return null
        val dir = File(root, id)
        val manifestBytes = File(dir, MANIFEST).takeIf { it.isFile }?.readBytes() ?: return null
        val sig = File(dir, SIGNATURE).takeIf { it.isFile }?.readBytes() ?: return null
        val signer = signer(manifestBytes, sig) ?: return null
        val manifest = try {
            PackManifest.parse(manifestBytes)
        } catch (e: PackException) {
            return null
        }
        if (manifest.id != id) return null
        val size = dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
        return InstalledPack(manifest, dir, size, keyId(signer))
    }

    /**
     * Re-checks an installed pack against its signed manifest: every listed file must exist with the
     * declared size and SHA-256. Null when [id] is not installed. Hashes whole files: call off the UI thread.
     */
    @Synchronized
    fun check(id: String): PackCheck? {
        if (!ID_RE.matches(id) || !File(root, id).isDirectory) return null
        val pack = open(id) ?: return PackCheck(id, manifestOk = false, missingFiles = 0, damagedFiles = 0)
        var missing = 0
        var damaged = 0
        val buffer = ByteArray(BUFFER)
        for (f in pack.manifest.files) {
            val file = File(pack.dir, f.path)
            if (!file.isFile) {
                missing++
                continue
            }
            if (file.length() != f.size) {
                damaged++
                continue
            }
            val digest = MessageDigest.getInstance("SHA-256")
            file.inputStream().use { input ->
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    digest.update(buffer, 0, n)
                }
            }
            if (digest.digest().toHex() != f.sha256) damaged++
        }
        return PackCheck(id, manifestOk = true, missingFiles = missing, damagedFiles = damaged)
    }

    /** [check] for every installed pack, sorted by id. Call off the UI thread. */
    @Synchronized
    fun checkAll(): List<PackCheck> = root.listFiles { f -> f.isDirectory && ID_RE.matches(f.name) }
        ?.map { it.name }?.sorted()?.mapNotNull { check(it) }
        ?: emptyList()

    /** Folder holding the pack's files (paths as in the manifest), or null when not installed. */
    fun dir(id: String): File? = open(id)?.dir

    /** First installed pack of [kind] whose languages contain all of [languages]. */
    fun find(kind: String, languages: List<String>): InstalledPack? =
        list().firstOrNull { it.manifest.kind == kind && it.manifest.languages.containsAll(languages) }

    /** Reads, verifies and installs a pack, replacing an installed one with the same id. */
    @Synchronized
    fun install(input: InputStream, maxBytes: Long = MAX_PACK_BYTES): InstalledPack {
        val data = DataInputStream(input.buffered(BUFFER))
        val manifestBytes: ByteArray
        val sig: ByteArray
        try {
            val magic = ByteArray(MAGIC.size)
            data.readFully(magic)
            if (!magic.contentEquals(MAGIC)) throw PackException("bad_format", "not a BooBoard pack")
            val version = data.readInt()
            if (version != FORMAT_VERSION) throw PackException("unsupported_version", "format $version")
            val manifestLen = data.readInt()
            if (manifestLen !in 2..MAX_MANIFEST) throw PackException("bad_format", "manifest length")
            manifestBytes = ByteArray(manifestLen).also { data.readFully(it) }
            val sigLen = data.readInt()
            if (sigLen !in 8..MAX_SIGNATURE) throw PackException("bad_format", "signature length")
            sig = ByteArray(sigLen).also { data.readFully(it) }
        } catch (e: EOFException) {
            throw PackException("bad_format", "truncated header")
        }
        if (signer(manifestBytes, sig) == null) throw PackException("bad_signature", "signature does not verify")
        val manifest = PackManifest.parse(manifestBytes)
        // Overflow-safe: a manifest whose sizes wrap around must not slip under the cap.
        val total = try {
            manifest.files.fold(0L) { acc, f ->
                if (f.size < 0 || f.size > maxBytes) throw PackException("too_large", "file too large")
                Math.addExact(acc, f.size)
            }
        } catch (e: ArithmeticException) {
            throw PackException("too_large", "pack is too large")
        }
        if (total > maxBytes) throw PackException("too_large", "pack is $total bytes")
        root.mkdirs()
        // usableSpace is 0 when the platform cannot tell; then the write itself reports a full disk.
        val free = root.usableSpace
        if (free > 0L && free < total + FREE_SPACE_MARGIN) throw PackException("no_space", "not enough space")

        val tmp = File(root, ".tmp-${manifest.id}-${System.nanoTime()}")
        try {
            tmp.mkdirs()
            val buffer = ByteArray(BUFFER)
            for (f in manifest.files) {
                val out = File(tmp, f.path)
                out.parentFile?.mkdirs()
                val digest = MessageDigest.getInstance("SHA-256")
                out.outputStream().use { os ->
                    var left = f.size
                    while (left > 0) {
                        val n = data.read(buffer, 0, minOf(buffer.size.toLong(), left).toInt())
                        if (n < 0) throw PackException("bad_format", "truncated file")
                        digest.update(buffer, 0, n)
                        os.write(buffer, 0, n)
                        left -= n
                    }
                }
                if (digest.digest().toHex() != f.sha256) throw PackException("bad_signature", "file hash mismatch")
            }
            if (data.read() != -1) throw PackException("bad_format", "trailing data")
            File(tmp, MANIFEST).writeBytes(manifestBytes)
            File(tmp, SIGNATURE).writeBytes(sig)

            val target = File(root, manifest.id)
            val old = File(root, ".old-${manifest.id}-${System.nanoTime()}")
            if (target.exists() && !target.renameTo(old)) throw PackException("bad_format", "cannot replace pack")
            if (!tmp.renameTo(target)) {
                old.renameTo(target)
                throw PackException("bad_format", "cannot install pack")
            }
            old.deleteRecursively()
            return open(manifest.id) ?: throw PackException("bad_format", "installed pack unreadable")
        } finally {
            if (tmp.exists()) tmp.deleteRecursively()
        }
    }

    @Synchronized
    fun delete(id: String) {
        if (!ID_RE.matches(id)) return
        File(root, id).deleteRecursively()
    }

    /** Removes leftovers of interrupted installs. */
    @Synchronized
    fun cleanUp() {
        root.listFiles { f -> f.name.startsWith(".tmp-") || f.name.startsWith(".old-") }?.forEach {
            it.deleteRecursively()
        }
    }

    /** The trusted key that verifies [sig] over [manifest], or null. */
    private fun signer(manifest: ByteArray, sig: ByteArray): PublicKey? = trustedKeys.firstOrNull { key ->
        try {
            Signature.getInstance("SHA256withECDSA").run {
                initVerify(key)
                update(manifest)
                verify(sig)
            }
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        const val FORMAT_VERSION = 1
        const val MANIFEST = "manifest.json"
        const val SIGNATURE = "manifest.sig"
        const val MAX_PACK_BYTES = 2L * 1024 * 1024 * 1024
        const val MAX_FILES = 64
        private const val MAX_MANIFEST = 64 * 1024
        private const val MAX_SIGNATURE = 512
        private const val BUFFER = 64 * 1024
        private const val FREE_SPACE_MARGIN = 16L * 1024 * 1024
        private const val KEY_ID_BYTES = 8
        internal val MAGIC = "BOOPACK1".toByteArray(Charsets.US_ASCII)
        internal val ID_RE = Regex("[a-z0-9][a-z0-9._-]{0,63}")

        @Volatile
        private var instance: PackStore? = null

        /** One store per process (both engines share its lock). */
        fun get(context: Context): PackStore = instance ?: synchronized(this) {
            instance ?: PackStore(
                File(context.noBackupFilesDir, "packs"),
                PackKeys.trusted(debuggable = isDebuggable(context)),
            ).also {
                it.cleanUp()
                instance = it
            }
        }

        /** Debug builds (and only they) also trust the development key. */
        internal fun isDebuggable(context: Context): Boolean =
            (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

        /** Key id: the first 8 bytes of SHA-256 over the DER public key, as lowercase hex. */
        fun keyId(key: PublicKey): String =
            MessageDigest.getInstance("SHA-256").digest(key.encoded).copyOf(KEY_ID_BYTES).toHex()

        fun publicKey(base64Der: String): PublicKey =
            KeyFactory.getInstance("EC").generatePublic(X509EncodedKeySpec(Base64.getDecoder().decode(base64Der)))
    }
}

/** An installed pack whose manifest verified. [signerKeyId] is the id of the trusted key that signed it. */
data class InstalledPack(
    val manifest: PackManifest,
    val dir: File,
    val sizeBytes: Long,
    /** Empty when the pack was built by hand in a test; [PackStore.open] always sets it. */
    val signerKeyId: String = "",
)

/**
 * Result of re-checking one installed pack. [manifestOk] is false when the signed manifest no longer
 * verifies (or cannot be parsed). Counts are files; no paths are returned, so none can leak to the UI.
 */
data class PackCheck(val id: String, val manifestOk: Boolean, val missingFiles: Int, val damagedFiles: Int) {
    val ok: Boolean get() = manifestOk && missingFiles == 0 && damagedFiles == 0
}

class PackException(val code: String, message: String) : Exception(message)

internal fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }
