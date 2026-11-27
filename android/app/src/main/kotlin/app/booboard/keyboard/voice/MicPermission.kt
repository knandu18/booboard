// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Microphone permission. An IME cannot show a permission dialog itself, so [request] starts the
 * transparent, non-exported [MicPermissionActivity] and resumes with the user's answer. OWNER: Wave 3-D.
 */
object MicPermission {
    /** How long to wait for the permission screen before giving up (the user may have left it open). */
    private const val TIMEOUT_MS = 120_000L

    private val TIMEOUT_TOKEN = Any()
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var pending: ((Boolean) -> Unit)? = null

    fun granted(context: Context): Boolean =
        context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    /** Launches [MicPermissionActivity] and returns the answer. Already granted: true without a screen. */
    suspend fun request(context: Context): Boolean {
        if (granted(context)) return true
        return suspendCancellableCoroutine { cont ->
            pending = { answer ->
                main.removeCallbacksAndMessages(TIMEOUT_TOKEN)
                if (cont.isActive) cont.resume(answer)
            }
            cont.invokeOnCancellation { pending = null }
            main.postAtTime({ deliver(false) }, TIMEOUT_TOKEN, SystemClock.uptimeMillis() + TIMEOUT_MS)
            try {
                context.startActivity(
                    Intent(context, MicPermissionActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
            } catch (e: Exception) {
                deliver(false)
            }
        }
    }

    /** Called by the activity with the answer, or false when it ends without one. */
    internal fun deliver(granted: Boolean) {
        val callback = pending ?: return
        pending = null
        callback(granted)
    }
}

/** Transparent activity that only asks for RECORD_AUDIO and finishes. Not exported. OWNER: Wave 3-D. */
class MicPermissionActivity : Activity() {
    private var asked = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (MicPermission.granted(this)) {
            MicPermission.deliver(true)
            finish()
            return
        }
        if (!asked) {
            asked = true
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (requestCode == REQUEST_CODE) {
            val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            MicPermission.deliver(ok)
            finish()
        } else {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun onDestroy() {
        // Back press or the system closed the screen without an answer.
        MicPermission.deliver(false)
        super.onDestroy()
    }

    private companion object {
        const val REQUEST_CODE = 0x4D31
    }
}
