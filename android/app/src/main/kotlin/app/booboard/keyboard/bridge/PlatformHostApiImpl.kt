// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.bridge

import android.Manifest
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Paint
import android.os.Build
import app.booboard.keyboard.packs.PackStore
import app.booboard.keyboard.security.SecureStore
import app.booboard.keyboard.security.SecureStoreException
import java.io.File

internal enum class EngineRole { IME, APP }

/** Calls available to both engines. Secure-store calls arrive on a background thread. */
internal class PlatformHostApiImpl(
    private val context: Context,
    private val role: EngineRole,
) : PlatformHostApi {

    // One store per process: both engines must share its lock.
    private val store by lazy { SecureStore.get(context) }

    override fun getSystemColors(): SystemColorsMessage? {
        if (Build.VERSION.SDK_INT < 31) return null
        val res = context.resources
        val palettes = ArrayList<Long>(PALETTES.size * TONES.size)
        for (palette in PALETTES) {
            for (tone in TONES) {
                @Suppress("DiscouragedApi")
                val id = res.getIdentifier("system_${palette}_$tone", "color", "android")
                palettes += if (id != 0) context.getColor(id).toLong() and 0xFFFFFFFFL else 0L
            }
        }
        return SystemColorsMessage(palettes, context.isNightMode())
    }

    /** Null when missing, corrupt, or the device is locked (the keyboard still works without it). */
    override fun secureRead(name: String): ByteArray? = secure { store.read(name) }

    /** Restore only: null when missing or damaged, `secure_store_locked` while the key is unusable (SEC-06). */
    override fun secureReadStrict(name: String): ByteArray? = secure { store.readStrict(name) }

    /** Throws a PlatformException (code `secure_store_*`) when the data could not be saved. */
    override fun secureWrite(name: String, data: ByteArray) = secure { store.write(name, data) }

    override fun secureDelete(name: String) = secure { store.delete(name) }

    override fun secureWipeAll() = secure { store.wipeAll() }

    override fun secureList(): List<SecureBlobInfo> = secure {
        store.list().map { SecureBlobInfo(it.name, it.sizeBytes, it.modifiedMillis) }
    }

    private inline fun <T> secure(block: () -> T): T = try {
        block()
    } catch (e: SecureStoreException) {
        throw FlutterError(e.code, e.message, null)
    }

    override fun hasInternetPermission(): Boolean {
        @Suppress("DEPRECATION")
        val info = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
        return info.requestedPermissions?.contains(Manifest.permission.INTERNET) == true
    }

    override fun getAppInfo(): AppInfoMessage {
        @Suppress("DEPRECATION")
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return AppInfoMessage(
            packageName = context.packageName,
            versionName = info.versionName ?: "",
            versionCode = code,
            sdkInt = Build.VERSION.SDK_INT.toLong(),
            isDebugBuild = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0,
        )
    }

    override fun hasGlyphs(texts: List<String>): List<Boolean> {
        val paint = Paint()
        return texts.map { paint.hasGlyph(it) }
    }

    override fun getDataDirectory(): String =
        File(context.noBackupFilesDir, "data").apply { mkdirs() }.absolutePath

    override fun notifySettingsChanged(sections: List<String>) = SettingsBus.publish(role, sections)

    override fun listPacks(): List<PackInfoMessage> = PackStore.get(context).list().map { it.toMessage() }

    override fun getPackDirectory(id: String): String? = PackStore.get(context).dir(id)?.absolutePath

    private companion object {
        val PALETTES = listOf("accent1", "accent2", "accent3", "neutral1", "neutral2")
        val TONES = listOf(0, 10, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000)
    }
}
