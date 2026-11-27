// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.bridge

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import androidx.activity.ComponentActivity
import android.net.Uri
import app.booboard.keyboard.packs.DeliveredPacks
import app.booboard.keyboard.packs.PackDownloads
import app.booboard.keyboard.packs.PackException
import app.booboard.keyboard.packs.PackSources
import app.booboard.keyboard.packs.PackStore
import app.booboard.keyboard.security.backup.BackupCrypto
import app.booboard.keyboard.security.backup.BackupDocuments
import app.booboard.keyboard.security.backup.BackupException

/** BooBoard's website, opened in the browser from Home and About (the app itself never goes online). */
private const val WEBSITE_URL = "https://booboard.com"

/**
 * Calls for the settings-app engine.
 *
 * OWNER: orchestrator, except the backup section at the bottom, which Wave 2-B implements
 * (Storage Access Framework documents and .boobackup crypto; helpers live in `security/backup/`).
 */
internal class AppHostApiImpl(
    private val activity: ComponentActivity,
    private val launchRoute: () -> String?,
) : AppHostApi {

    private val imm get() = activity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager

    /** Registers the document pickers, so it must be built before the activity starts. */
    private val documents = BackupDocuments(activity)

    override fun isBooBoardEnabled() = imm.enabledInputMethodList.any { it.packageName == activity.packageName }

    override fun isBooBoardSelected(): Boolean {
        val id = Settings.Secure.getString(activity.contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?: return false
        return id.startsWith(activity.packageName + "/")
    }

    override fun openInputMethodSettings() {
        activity.startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
    }

    override fun showInputMethodPicker() = imm.showInputMethodPicker()

    override fun setSecureScreen(secure: Boolean) {
        activity.runOnUiThread {
            if (secure) activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            if (Build.VERSION.SDK_INT >= 33) activity.setRecentsScreenshotEnabled(!secure)
        }
    }

    override fun takeLaunchRoute(): String? = launchRoute()

    // ---- Backup files and crypto: Wave 2-B ---------------------------------------------

    // Pigeon runs these suspend functions on Dispatchers.Main.
    override suspend fun createDocument(suggestedName: String, mimeType: String): String? =
        backupErrors { documents.create(suggestedName, mimeType) }

    override suspend fun openDocument(mimeTypes: List<String>): String? =
        backupErrors { documents.open(mimeTypes) }

    override fun writeDocument(uri: String, data: ByteArray): Unit = backupErrors { documents.write(uri, data) }

    override fun readDocument(uri: String, maxBytes: Long): ByteArray = backupErrors { documents.read(uri, maxBytes) }

    override fun sealBackup(plain: ByteArray, passphrase: String): ByteArray =
        backupErrors { BackupCrypto.seal(plain, passphrase) }

    override fun openBackup(sealed: ByteArray, passphrase: String): ByteArray? =
        backupErrors { BackupCrypto.open(sealed, passphrase) }

    // ---- Model packs (Wave 3) ---------------------------------------------------------

    override fun importPack(uri: String): PackInfoMessage {
        val parsed = Uri.parse(uri)
        if (parsed.scheme != "content") throw FlutterError("bad_format", "not a content document", null)
        val input = activity.contentResolver.openInputStream(parsed)
            ?: throw FlutterError("bad_format", "cannot open document", null)
        return try {
            input.use { PackStore.get(activity).install(it).toMessage() }
        } catch (e: PackException) {
            throw FlutterError(e.code, e.message, null)
        }
    }

    override fun deletePack(id: String) = PackStore.get(activity).delete(id)

    // ---- Pack maintenance (Wave 5-C) ----------------------------------------------------

    private val packSource by lazy { PackSources.forBuild(activity) }

    override fun verifyPacks(): List<PackCheckMessage> =
        PackStore.get(activity).checkAll().map { it.toMessage() }

    override fun packStorage(): PackStorageMessage? {
        val free = activity.noBackupFilesDir.usableSpace
        return if (free > 0L) PackStorageMessage(free) else null
    }

    override fun packDelivery(): String = if (packSource.storeDelivered) "store" else "import"

    override fun packOffers(): List<PackOfferMessage> = packSource.offers().map { it.toMessage() }

    override fun requestPack(id: String) {
        try {
            packSource.request(id)
        } catch (e: UnsupportedOperationException) {
            throw FlutterError("unsupported", e.message, null)
        }
    }

    override fun installDeliveredPack(id: String): PackInfoMessage {
        val installed = try {
            DeliveredPacks.install(packSource, PackStore.get(activity), id)
        } catch (e: PackException) {
            throw FlutterError(e.code, e.message, null)
        } ?: throw FlutterError("not_delivered", "the store has not delivered this pack yet", null)
        return installed.toMessage()
    }

    override fun openPackDownload(fileName: String) {
        val url = PackDownloads.urlFor(fileName) ?: throw FlutterError("bad_link", "not a pack file name", null)
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addCategory(Intent.CATEGORY_BROWSABLE)
        try {
            activity.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            throw FlutterError("no_browser", "no app can open the link", null)
        }
    }

    override fun openWebsite() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(WEBSITE_URL)).addCategory(Intent.CATEGORY_BROWSABLE)
        try {
            activity.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            throw FlutterError("no_browser", "no app can open the link", null)
        }
    }

    /** Maps [BackupException] to the FlutterError code Dart matches on. */
    private inline fun <T> backupErrors(block: () -> T): T = try {
        block()
    } catch (e: BackupException) {
        throw FlutterError(e.code, e.message, null)
    }
}
