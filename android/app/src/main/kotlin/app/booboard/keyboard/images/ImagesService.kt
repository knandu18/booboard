// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

import android.app.Service
import android.content.ComponentCallbacks2
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.os.Process
import android.os.RemoteException
import android.util.Log
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * The picture helper. Runs in its own process (`:images`, see the manifest), bound by the keyboard
 * ([ImagesClient]), so running out of memory ends only this process, never the keyboard.
 * Not exported, no foreground service, no permissions. Speaks [ImagesProtocol] over a [Messenger].
 * The work is in [ImagesWorker]; this class only turns messages into calls and calls into messages.
 * Never logs the prompt.
 */
class ImagesService : Service() {
    private val main = Handler(Looper.getMainLooper())
    private var replyTo: Messenger? = null
    private lateinit var executor: ExecutorService
    private lateinit var worker: ImagesWorker
    private lateinit var messenger: Messenger

    private val freeWhenIdle = Runnable { worker.freeIfIdle(force = false) }

    private val listener = object : ImagesWorker.Listener {
        override fun onProgress(phase: Int, step: Int, steps: Int) {
            reply(ImagesProtocol.MSG_PROGRESS) {
                putInt(ImagesProtocol.KEY_PHASE, phase)
                putInt(ImagesProtocol.KEY_STEP, step)
                putInt(ImagesProtocol.KEY_STEPS, steps)
            }
        }

        override fun onDone(outPath: String, millis: Long) {
            reply(ImagesProtocol.MSG_DONE) {
                putString(ImagesProtocol.KEY_OUT, outPath)
                putLong(ImagesProtocol.KEY_MILLIS, millis)
            }
            armIdleFree()
        }

        override fun onCancelled() {
            reply(ImagesProtocol.MSG_CANCELLED) {}
            armIdleFree()
        }

        override fun onError(code: String, detail: String) {
            reply(ImagesProtocol.MSG_ERROR) {
                putString(ImagesProtocol.KEY_CODE, code)
                putString(ImagesProtocol.KEY_DETAIL, detail)
            }
            armIdleFree()
        }
    }

    override fun onCreate() {
        super.onCreate()
        executor = Executors.newSingleThreadExecutor { r ->
            Thread(
                {
                    // Pictures take a while; the phone and the keyboard come first.
                    Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
                    r.run()
                },
                "booboard-images",
            )
        }
        worker = ImagesWorker(
            engine = SdImageEngine(),
            executor = executor,
            threads = ImagesProtocol.engineThreads(Runtime.getRuntime().availableProcessors()),
            now = System::currentTimeMillis,
            listener = listener,
        )
        messenger = Messenger(
            Handler(Looper.getMainLooper()) { msg ->
                handle(msg)
                true
            },
        )
    }

    override fun onBind(intent: Intent?): IBinder = messenger.binder

    private fun handle(msg: Message) {
        when (msg.what) {
            ImagesProtocol.MSG_MAKE -> {
                msg.replyTo?.let { replyTo = it }
                main.removeCallbacks(freeWhenIdle)
                val job = jobFrom(msg.data)
                // Progress and the result come from the worker; a picture already running is answered with ERR_BUSY.
                if (job == null) listener.onError(ImagesProtocol.ERR_FAILED, "bad request") else worker.make(job)
            }

            ImagesProtocol.MSG_STOP -> worker.stop()
        }
    }

    private fun jobFrom(b: Bundle?): ImageJob? {
        b ?: return null
        val model = b.getString(ImagesProtocol.KEY_MODEL)
        val taesd = b.getString(ImagesProtocol.KEY_TAESD)
        val prompt = b.getString(ImagesProtocol.KEY_PROMPT)
        val out = b.getString(ImagesProtocol.KEY_OUT)
        if (model == null || taesd == null || prompt == null || out == null) return null
        return ImageJob(
            modelPath = model,
            taesdPath = taesd,
            prompt = prompt,
            seed = b.getLong(ImagesProtocol.KEY_SEED),
            steps = b.getInt(ImagesProtocol.KEY_STEPS, ImagesProtocol.DEFAULT_STEPS),
            width = b.getInt(ImagesProtocol.KEY_WIDTH, ImagesProtocol.DEFAULT_SIZE),
            height = b.getInt(ImagesProtocol.KEY_HEIGHT, ImagesProtocol.DEFAULT_SIZE),
            cfg = b.getFloat(ImagesProtocol.KEY_CFG, ImagesProtocol.DEFAULT_CFG),
            outPath = out,
        )
    }

    /** Sends one message to the keyboard; a keyboard that is gone is not an error. */
    private fun reply(what: Int, fill: Bundle.() -> Unit) {
        val to = replyTo ?: return
        val m = Message.obtain(null, what)
        m.data = Bundle().apply(fill)
        try {
            to.send(m)
        } catch (e: RemoteException) {
            Log.w(TAG, "keyboard is gone")
        }
    }

    /** After a picture: free the model if nothing else is asked for a while. */
    private fun armIdleFree() {
        main.removeCallbacks(freeWhenIdle)
        main.postDelayed(freeWhenIdle, ImagesProtocol.IDLE_FREE_MS)
    }

    // TRIM_MEMORY_RUNNING_LOW is deprecated from API 34 but is still what older phones send.
    @Suppress("DEPRECATION")
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) worker.freeIfIdle(force = true)
    }

    override fun onDestroy() {
        main.removeCallbacks(freeWhenIdle)
        worker.shutdown()
        executor.shutdown()
        super.onDestroy()
    }

    private companion object {
        const val TAG = "BooBoardImages"
    }
}
