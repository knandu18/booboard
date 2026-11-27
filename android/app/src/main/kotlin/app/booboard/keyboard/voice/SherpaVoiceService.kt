// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import app.booboard.keyboard.bridge.VoiceEventKind
import app.booboard.keyboard.bridge.VoiceEventMessage
import app.booboard.keyboard.bridge.VoiceRequestMessage
import app.booboard.keyboard.bridge.VoiceStartStatus
import app.booboard.keyboard.packs.InstalledPack
import app.booboard.keyboard.packs.PackStore
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Everything [SherpaVoiceService] touches from outside, so the JVM tests can replace it. OWNER: Wave 3-D. */
internal class VoiceDeps(
    val openPack: (String) -> InstalledPack?,
    val listPacks: () -> List<InstalledPack>,
    val loadEngine: (dir: File, engine: String) -> SpeechEngine,
    val newMicrophone: () -> Microphone,
    val main: MainThread,
    val clock: Clock,
    val log: (String) -> Unit,
)

/**
 * Offline voice typing in English with a voice pack (Parakeet). Calls arrive on the main thread; the engine stays loaded
 * between sessions and is released 60 s after the last one (or on [release]).
 */
internal class SherpaVoiceService(private val deps: VoiceDeps) : VoiceService {
    private var session: VoiceSession? = null
    private var starting = false
    private var pendingEnd: PendingEnd? = null
    private var releaseWhenIdle = false
    private var idleEpoch = 0
    private var loaded: LoadedEngine? = null

    private enum class PendingEnd { STOP, CANCEL }

    private class LoadedEngine(val packId: String, val engine: SpeechEngine)

    override suspend fun start(request: VoiceRequestMessage, events: VoiceEvents): VoiceStartStatus {
        if (session != null || starting) return VoiceStartStatus.BUSY
        starting = true
        try {
            val pack = resolveVoicePack(request.packId, request.language, deps.openPack, deps.listPacks)
                ?: return VoiceStartStatus.NO_MODEL
            val engine = engineFor(pack) ?: return VoiceStartStatus.FAILED

            val mic = deps.newMicrophone()
            if (!mic.start()) {
                deps.log("microphone busy")
                events.emit(VoiceEventMessage(kind = VoiceEventKind.ERROR, level = 0.0, errorCode = "audio_busy"))
                events.emit(VoiceEventMessage(kind = VoiceEventKind.STOPPED, level = 0.0))
                scheduleIdleRelease()
                return VoiceStartStatus.BUSY
            }
            val s = VoiceSession(
                mic = mic,
                engine = engine,
                main = deps.main,
                emit = { event -> events.emit(event) },
                clock = deps.clock,
                onEnded = { onSessionEnded() },
            )
            session = s
            deps.log("session started, pack ${pack.manifest.id}")
            s.start()
            when (pendingEnd) {
                PendingEnd.CANCEL -> s.requestCancel()
                PendingEnd.STOP -> s.requestStop()
                null -> Unit
            }
            pendingEnd = null
            return VoiceStartStatus.STARTED
        } finally {
            starting = false
        }
    }

    override fun stop() {
        val s = session
        if (s != null) s.requestStop() else if (starting) pendingEnd = PendingEnd.STOP
    }

    override fun cancel() {
        val s = session
        if (s != null) s.requestCancel() else if (starting) pendingEnd = PendingEnd.CANCEL
    }

    override fun release() {
        val s = session
        if (s != null) {
            // The decode thread still uses the engine: unload when the session has ended.
            releaseWhenIdle = true
            s.requestCancel()
        } else if (!starting) {
            unloadEngine()
        }
    }

    /** The loaded engine for [pack], loading it off the main thread when needed. */
    private suspend fun engineFor(pack: InstalledPack): SpeechEngine? {
        val current = loaded
        if (current != null && current.packId == pack.manifest.id) return current.engine
        unloadEngine()
        val t0 = deps.clock.nowMs()
        val engine = try {
            withContext(Dispatchers.IO) { deps.loadEngine(pack.dir, pack.manifest.engine) }
        } catch (e: Throwable) {
            // Includes UnsatisfiedLinkError when the native library does not load: report FAILED, never crash.
            deps.log("model load failed: ${e.javaClass.simpleName}")
            return null
        }
        deps.log("model loaded in ${deps.clock.nowMs() - t0} ms")
        loaded = LoadedEngine(pack.manifest.id, engine)
        return engine
    }

    private fun onSessionEnded() {
        session = null
        if (releaseWhenIdle) {
            releaseWhenIdle = false
            unloadEngine()
        } else {
            scheduleIdleRelease()
        }
    }

    private fun scheduleIdleRelease() {
        val epoch = ++idleEpoch
        deps.main.postDelayed(IDLE_RELEASE_MS) {
            if (epoch == idleEpoch && session == null && !starting) unloadEngine()
        }
    }

    private fun unloadEngine() {
        val current = loaded ?: return
        loaded = null
        current.engine.release()
        deps.log("model released")
    }

    private companion object {
        const val IDLE_RELEASE_MS = 60_000L
    }
}

/** The production voice service, used by `ImeHostApiImpl`. Keeps the `VoiceService` interface. */
internal fun newSherpaVoiceService(context: Context, packs: PackStore): VoiceService {
    val handler = Handler(Looper.getMainLooper())
    val main = object : MainThread {
        override fun post(block: () -> Unit) {
            handler.post(block)
        }

        override fun postDelayed(delayMs: Long, block: () -> Unit) {
            handler.postDelayed(block, delayMs)
        }
    }
    return SherpaVoiceService(
        VoiceDeps(
            openPack = { id -> packs.open(id) },
            listPacks = { packs.list() },
            loadEngine = { dir, engine -> loadSherpaEngine(dir, engine) },
            newMicrophone = { AudioRecordMicrophone() },
            main = main,
            clock = Clock { SystemClock.elapsedRealtime() },
            log = { message -> Log.d(TAG, message) },
        ),
    )
}

private const val TAG = "BooBoardVoice"
