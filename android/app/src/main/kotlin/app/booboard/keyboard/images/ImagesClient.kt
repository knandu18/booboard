// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.RemoteException
import android.util.Log
import app.booboard.keyboard.bridge.ImageEventKind
import app.booboard.keyboard.bridge.ImageEventMessage
import app.booboard.keyboard.bridge.ImageRequestMessage
import app.booboard.keyboard.bridge.ImageStartStatus
import app.booboard.keyboard.packs.PackStore
import java.io.File
import java.security.SecureRandom

fun interface ImageEvents {
    fun emit(event: ImageEventMessage)
}

/**
 * The keyboard's side of picture making: binds [ImagesService] (the `:images` process) when a picture is asked
 * for, sends it the job, and forwards its answers to [events] on the main thread. Everything here runs on the main
 * thread. The helper is unbound a while after the last result so its process can end and its memory is returned;
 * if it dies mid-picture (most likely closed for memory) the picture ends with the error `helper_died` and the
 * keyboard keeps running. Never logs the prompt.
 */
class ImagesClient(
    private val context: Context,
    private val packs: PackStore,
    private val events: ImageEvents,
    private val clock: () -> Long = System::currentTimeMillis,
) {
    private val main = Handler(Looper.getMainLooper())
    private val random = SecureRandom()

    /** A picture was accepted and has not ended yet. */
    private var active = false
    private var bound = false
    private var service: Messenger? = null

    /** The job waiting for the helper to connect. */
    private var pending: Bundle? = null

    private val replies = Messenger(
        Handler(Looper.getMainLooper()) { msg ->
            onReply(msg)
            true
        },
    )

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
            service = Messenger(binder)
            pending?.let {
                pending = null
                send(ImagesProtocol.MSG_MAKE, it)
            }
        }

        override fun onServiceDisconnected(name: ComponentName) = helperGone()

        override fun onBindingDied(name: ComponentName) = helperGone()

        override fun onNullBinding(name: ComponentName) = helperGone()
    }

    private val unbindWhenIdle = Runnable { if (!active) unbind() }

    /** Starts one picture. Progress and the result arrive through [events]; the status says whether it started. */
    fun make(request: ImageRequestMessage): ImageStartStatus {
        if (!ImagesAbi.supported(Build.SUPPORTED_ABIS.firstOrNull())) return ImageStartStatus.UNSUPPORTED
        if (active) return ImageStartStatus.BUSY
        val files = ImagesPack.find(packs) ?: return ImageStartStatus.NO_PACK
        val out = ImagesFiles.newOutput(File(context.cacheDir, "images"), clock())
        val job = Bundle().apply {
            putString(ImagesProtocol.KEY_MODEL, files.modelPath)
            putString(ImagesProtocol.KEY_TAESD, files.taesdPath)
            putString(ImagesProtocol.KEY_PROMPT, request.prompt.take(MAX_PROMPT))
            putLong(ImagesProtocol.KEY_SEED, request.seed ?: (random.nextLong() and Long.MAX_VALUE))
            putInt(ImagesProtocol.KEY_STEPS, ImagesProtocol.DEFAULT_STEPS)
            putInt(ImagesProtocol.KEY_WIDTH, ImagesProtocol.DEFAULT_SIZE)
            putInt(ImagesProtocol.KEY_HEIGHT, ImagesProtocol.DEFAULT_SIZE)
            putFloat(ImagesProtocol.KEY_CFG, ImagesProtocol.DEFAULT_CFG)
            putString(ImagesProtocol.KEY_OUT, out.path)
        }
        main.removeCallbacks(unbindWhenIdle)
        if (!bound) {
            val intent = Intent(context, ImagesService::class.java)
            bound = try {
                context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
            } catch (e: SecurityException) {
                false
            }
            if (!bound) {
                // The system gave no connection; the connection object must still be released.
                bound = true
                unbind()
                return ImageStartStatus.UNSUPPORTED
            }
        }
        active = true
        if (service != null) send(ImagesProtocol.MSG_MAKE, job) else pending = job
        return ImageStartStatus.STARTED
    }

    /** Asks the helper to stop the picture; a `cancelled` event follows. Does nothing when idle. */
    fun stop() {
        if (!active) return
        if (service == null) {
            // Still connecting: nothing started yet.
            pending = null
            active = false
            unbind()
            events.emit(ImageEventMessage(ImageEventKind.CANCELLED, 0, 0))
        } else {
            send(ImagesProtocol.MSG_STOP, null)
        }
    }

    /** Memory is low in the keyboard: let the helper go when no picture is running. */
    fun releaseIfIdle() {
        if (!active) unbind()
    }

    /** The keyboard is closing: drop the helper, which ends any picture and frees its model. No events. */
    fun release() {
        active = false
        pending = null
        unbind()
    }

    private fun send(what: Int, data: Bundle?) {
        val to = service ?: return
        val msg = Message.obtain(null, what)
        msg.replyTo = replies
        if (data != null) msg.data = data
        try {
            to.send(msg)
        } catch (e: RemoteException) {
            helperGone()
        }
    }

    private fun onReply(msg: Message) {
        if (!active) return
        val d = msg.data
        val event = ImageReplies.toEvent(
            what = msg.what,
            phase = d.getInt(ImagesProtocol.KEY_PHASE),
            step = d.getInt(ImagesProtocol.KEY_STEP),
            steps = d.getInt(ImagesProtocol.KEY_STEPS),
            path = d.getString(ImagesProtocol.KEY_OUT),
            millis = d.getLong(ImagesProtocol.KEY_MILLIS),
            code = d.getString(ImagesProtocol.KEY_CODE),
        ) ?: return
        if (event.kind == ImageEventKind.ERROR) {
            // The engine's text carries no prompt (contract with the native side); it stays out of Dart.
            Log.w(TAG, "picture failed: ${event.error} ${d.getString(ImagesProtocol.KEY_DETAIL).orEmpty().take(200)}")
        }
        if (ImageReplies.isFinal(event)) {
            active = false
            main.removeCallbacks(unbindWhenIdle)
            main.postDelayed(unbindWhenIdle, ImagesProtocol.CLIENT_UNBIND_MS)
        }
        events.emit(event)
    }

    /** The helper process is gone (closed for memory, crashed or killed). The keyboard goes on. */
    private fun helperGone() {
        val wasActive = active
        active = false
        pending = null
        unbind()
        if (wasActive) {
            Log.w(TAG, "helper ended during a picture")
            events.emit(ImageEventMessage(ImageEventKind.ERROR, 0, 0, error = ImagesProtocol.ERR_HELPER_DIED))
        }
    }

    private fun unbind() {
        main.removeCallbacks(unbindWhenIdle)
        service = null
        if (!bound) return
        bound = false
        try {
            context.unbindService(connection)
        } catch (e: IllegalArgumentException) {
            // Already unbound.
        }
    }

    private companion object {
        const val TAG = "BooBoardImages"

        /** The model reads about 77 tokens; more text only costs time here. */
        const val MAX_PROMPT = 1000
    }
}
