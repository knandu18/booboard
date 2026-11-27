// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.security

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import android.security.keystore.UserNotAuthenticatedException
import java.security.KeyStore
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/** Non-exportable AES-256 key in the Android Keystore (StrongBox when the device has one). */
internal class AndroidKeystoreKeyProvider(private val context: Context) : KeyProvider {

    override fun key(): SecretKey {
        (keyStore().getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.let { return it.secretKey }
        return try {
            generateKey(strongBox = Build.VERSION.SDK_INT >= 28)
        } catch (e: Exception) {
            if (Build.VERSION.SDK_INT >= 28 && e is StrongBoxUnavailableException) generateKey(strongBox = false)
            else throw e
        }
    }

    override fun deleteKey() {
        keyStore().deleteEntry(KEY_ALIAS)
    }

    override fun classify(error: Throwable): KeyFailure {
        var t: Throwable? = error
        var depth = 0
        while (t != null && depth++ < 8) {
            if (t is KeyPermanentlyInvalidatedException) return KeyFailure.INVALIDATED
            if (t is UserNotAuthenticatedException) return KeyFailure.LOCKED
            t = t.cause
        }
        // Keystore reports a locked device through assorted generic exceptions.
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        return if (keyguard?.isDeviceLocked == true) KeyFailure.LOCKED else KeyFailure.OTHER
    }

    private fun keyStore() = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    private fun generateKey(strongBox: Boolean): SecretKey {
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setRandomizedEncryptionRequired(true)
            .apply {
                if (Build.VERSION.SDK_INT >= 28) {
                    setIsStrongBoxBacked(strongBox)
                    // Typing data is only readable while the phone is unlocked.
                    setUnlockedDeviceRequired(true)
                }
            }
            .build()
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        generator.init(spec)
        return generator.generateKey()
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "booboard.secure_store.v1"
    }
}
