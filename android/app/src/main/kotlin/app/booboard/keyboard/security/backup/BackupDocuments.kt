// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.security.backup

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import java.io.ByteArrayOutputStream
import java.io.IOException
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Backup files chosen through the Storage Access Framework, so BooBoard needs no storage permission.
 *
 * The launchers are registered in the constructor, which runs during the activity's onCreate, as
 * ActivityResultRegistry requires. Only one picker may be open at a time; a second call fails with
 * [BackupException.BUSY]. The pickers run on the main thread.
 */
internal class BackupDocuments(private val activity: ComponentActivity) {

    private val resolver get() = activity.contentResolver

    private var pending: CancellableContinuation<Uri?>? = null

    private val createLauncher: ActivityResultLauncher<Pair<String, String>> =
        activity.registerForActivityResult(CreateDocumentContract) { deliver(it) }

    private val openLauncher: ActivityResultLauncher<List<String>> =
        activity.registerForActivityResult(OpenDocumentContract) { deliver(it) }

    /** ACTION_CREATE_DOCUMENT. Returns the content URI, or null when the user cancels. */
    suspend fun create(suggestedName: String, mimeType: String): String? =
        pick { createLauncher.launch(suggestedName to mimeType) }?.toString()

    /** ACTION_OPEN_DOCUMENT. Returns the content URI, or null when the user cancels. */
    suspend fun open(mimeTypes: List<String>): String? =
        pick { openLauncher.launch(mimeTypes) }?.toString()

    /** Only `content://` documents from the system picker are accepted: never a `file://` or other scheme (SEC-15). */
    private fun contentUri(uri: String): Uri {
        val parsed = Uri.parse(uri)
        if (parsed.scheme != "content") throw BackupException(BackupException.IO, "not a content document")
        return parsed
    }

    /** Replaces the document's contents. */
    fun write(uri: String, data: ByteArray) {
        try {
            val stream = resolver.openOutputStream(contentUri(uri), "wt")
                ?: throw BackupException(BackupException.IO, "document cannot be opened for writing")
            stream.use { it.write(data) }
        } catch (e: IOException) {
            throw BackupException(BackupException.IO, "could not write the backup file")
        }
    }

    /** Reads at most [maxBytes]; throws [BackupException.TOO_LARGE] beyond that. */
    fun read(uri: String, maxBytes: Long): ByteArray {
        try {
            val stream = resolver.openInputStream(contentUri(uri))
                ?: throw BackupException(BackupException.IO, "document cannot be opened for reading")
            stream.use { input ->
                val out = ByteArrayOutputStream()
                val buffer = ByteArray(BUFFER_BYTES)
                var total = 0L
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    total += n
                    if (total > maxBytes) {
                        throw BackupException(BackupException.TOO_LARGE, "backup file is larger than $maxBytes bytes")
                    }
                    out.write(buffer, 0, n)
                }
                return out.toByteArray()
            }
        } catch (e: IOException) {
            throw BackupException(BackupException.IO, "could not read the backup file")
        }
    }

    private suspend fun pick(launch: () -> Unit): Uri? = suspendCancellableCoroutine { cont ->
        if (pending != null) {
            cont.resumeWithException(BackupException(BackupException.BUSY, "another file picker is open"))
        } else {
            pending = cont
            cont.invokeOnCancellation {
                if (pending === cont) {
                    pending = null
                }
            }
            launch()
        }
    }

    private fun deliver(uri: Uri?) {
        val waiting = pending ?: return
        pending = null
        waiting.resume(uri)
    }

    private companion object {
        const val BUFFER_BYTES = 8 * 1024
    }
}

/** ACTION_CREATE_DOCUMENT with a MIME type and a suggested name chosen per call. */
private object CreateDocumentContract : ActivityResultContract<Pair<String, String>, Uri?>() {
    override fun createIntent(context: Context, input: Pair<String, String>): Intent =
        Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(input.second)
            .putExtra(Intent.EXTRA_TITLE, input.first)

    override fun parseResult(resultCode: Int, intent: Intent?): Uri? =
        if (resultCode == Activity.RESULT_OK) intent?.data else null
}

/** ACTION_OPEN_DOCUMENT restricted to the given MIME types. */
private object OpenDocumentContract : ActivityResultContract<List<String>, Uri?>() {
    override fun createIntent(context: Context, input: List<String>): Intent {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
        if (input.isNotEmpty()) intent.putExtra(Intent.EXTRA_MIME_TYPES, input.toTypedArray())
        return intent
    }

    override fun parseResult(resultCode: Int, intent: Intent?): Uri? =
        if (resultCode == Activity.RESULT_OK) intent?.data else null
}
