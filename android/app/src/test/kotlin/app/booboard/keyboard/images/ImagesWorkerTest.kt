// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

import java.io.File
import java.nio.file.Files
import java.util.concurrent.Executor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** The helper's logic with a fake engine and an executor the test runs by hand. No Android classes. */
class ImagesWorkerTest {
    /** Runs queued work only when the test says so, so "busy" and "queued" states can be checked. */
    private class ManualExecutor : Executor {
        private val queue = ArrayDeque<Runnable>()
        override fun execute(command: Runnable) {
            queue.addLast(command)
        }

        val pending get() = queue.size

        fun runAll() {
            while (queue.isNotEmpty()) queue.removeFirst().run()
        }
    }

    private class FakeEngine : ImageEngine {
        var available = true
        var loadOk = true
        var generateResult = SdNative.RESULT_OK
        var error = ""
        var throwOnGenerate: Throwable? = null
        var ignoreCancel = false
        var onLoad: () -> Unit = {}
        var onGenerate: (ImageJob) -> Unit = {}
        val calls = mutableListOf<String>()
        val prompts = mutableListOf<String>()
        private var cancelled = false

        override fun isAvailable() = available

        override fun load(modelPath: String, taesdPath: String, threads: Int, progress: ImageProgress): Boolean {
            calls += "load:$modelPath:$threads"
            progress.onProgress(ImagesProtocol.PHASE_LOADING, 0, 0)
            onLoad()
            return loadOk
        }

        override fun generate(job: ImageJob, progress: ImageProgress): Int {
            calls += "generate"
            prompts += job.prompt
            cancelled = false
            progress.onProgress(ImagesProtocol.PHASE_SAMPLING, 1, job.steps)
            onGenerate(job)
            throwOnGenerate?.let { throw it }
            if (generateResult == SdNative.RESULT_OK) {
                File(job.outPath).writeBytes(byteArrayOf(1))
                progress.onProgress(ImagesProtocol.PHASE_DECODING, 0, 0)
            }
            return if (cancelled && !ignoreCancel) SdNative.RESULT_CANCELLED else generateResult
        }

        override fun cancel() {
            calls += "cancel"
            cancelled = true
        }

        override fun free() {
            calls += "free"
        }

        override fun lastError() = error
    }

    private class Events : ImagesWorker.Listener {
        val log = mutableListOf<String>()
        var onDoneHook: () -> Unit = {}

        override fun onProgress(phase: Int, step: Int, steps: Int) {
            log += "progress:$phase:$step:$steps"
        }

        override fun onDone(outPath: String, millis: Long) {
            log += "done:${File(outPath).name}:$millis"
            onDoneHook()
        }

        override fun onCancelled() {
            log += "cancelled"
        }

        override fun onError(code: String, detail: String) {
            log += "error:$code:$detail"
        }
    }

    private val engine = FakeEngine()
    private val executor = ManualExecutor()
    private val events = Events()
    private var clock = 1_000L
    private lateinit var dir: File
    private lateinit var worker: ImagesWorker

    @Before
    fun setUp() {
        dir = Files.createTempDirectory("images").toFile()
        worker = ImagesWorker(engine, executor, threads = 4, now = { clock }, listener = events)
    }

    private fun job(name: String = "a", model: String = "m.gguf") = ImageJob(
        modelPath = model,
        taesdPath = "t.safetensors",
        prompt = "secret prompt",
        seed = 42,
        outPath = File(dir, "$name.png").path,
    )

    @Test
    fun makesAPictureLoadingTheModelFirst() {
        engine.onGenerate = { clock += 5_000 }
        assertTrue(worker.make(job()))
        assertTrue(worker.isBusy)
        executor.runAll()
        assertEquals(listOf("load:m.gguf:4", "generate"), engine.calls)
        assertEquals(
            listOf("progress:0:0:0", "progress:0:0:0", "progress:1:1:4", "progress:2:0:0", "done:a.png:5000"),
            events.log,
        )
        assertFalse(worker.isBusy)
        assertTrue(worker.isLoaded)
        assertEquals(listOf("secret prompt"), engine.prompts)
    }

    @Test
    fun theLoadedModelIsKeptForTheNextPicture() {
        worker.make(job("a"))
        executor.runAll()
        worker.make(job("b"))
        executor.runAll()
        assertEquals(listOf("load:m.gguf:4", "generate", "generate"), engine.calls)
    }

    @Test
    fun aDifferentModelFreesTheOldOneThenLoads() {
        worker.make(job("a", model = "one.gguf"))
        executor.runAll()
        worker.make(job("b", model = "two.gguf"))
        executor.runAll()
        assertEquals(listOf("load:one.gguf:4", "generate", "free", "load:two.gguf:4", "generate"), engine.calls)
    }

    @Test
    fun aSecondPictureWhileBusyIsRefusedAndTheFirstStillFinishes() {
        assertTrue(worker.make(job("a")))
        assertFalse(worker.make(job("b")))
        assertEquals("error:busy:", events.log.single())
        assertEquals(1, executor.pending)
        executor.runAll()
        assertEquals(1, engine.prompts.size)
        assertTrue(events.log.last().startsWith("done:a.png"))
    }

    @Test
    fun theWorkerIsFreeWhenTheResultIsReported() {
        var second: Boolean? = null
        events.onDoneHook = {
            events.onDoneHook = {}
            second = worker.make(job("b"))
        }
        worker.make(job("a"))
        executor.runAll()
        assertEquals(true, second)
        assertEquals(2, engine.prompts.size)
    }

    @Test
    fun stoppingDuringTheSamplingCancelsAndDeletesTheUnfinishedFile() {
        val out = File(dir, "a.png")
        engine.onGenerate = {
            out.writeBytes(byteArrayOf(9))
            worker.stop()
        }
        worker.make(job("a"))
        executor.runAll()
        assertTrue(engine.calls.contains("cancel"))
        assertEquals("cancelled", events.log.last())
        assertFalse(out.exists())
        assertFalse(worker.isBusy)
        // The model stays loaded for the next picture.
        assertTrue(worker.isLoaded)
    }

    @Test
    fun stoppingDuringTheLoadSkipsTheSampling() {
        engine.onLoad = { worker.stop() }
        worker.make(job())
        executor.runAll()
        assertEquals(listOf("load:m.gguf:4", "cancel"), engine.calls)
        assertEquals("cancelled", events.log.last())
    }

    @Test
    fun stoppingWhileIdleDoesNothing() {
        worker.stop()
        assertTrue(engine.calls.isEmpty())
        assertTrue(events.log.isEmpty())
    }

    @Test
    fun aStopAfterTheEngineFinishedStillReportsThePicture() {
        engine.ignoreCancel = true
        engine.onGenerate = { worker.stop() }
        worker.make(job())
        executor.runAll()
        assertTrue(events.log.last().startsWith("done:"))
        assertTrue(File(dir, "a.png").exists())
    }

    @Test
    fun noEngineOnThisPhoneIsUnsupported() {
        engine.available = false
        worker.make(job())
        executor.runAll()
        assertEquals(listOf("error:unsupported:"), events.log)
        assertTrue(engine.calls.isEmpty())
        assertFalse(worker.isBusy)
    }

    @Test
    fun aModelThatWillNotLoadReportsTheEnginesText() {
        engine.loadOk = false
        engine.error = "bad gguf"
        worker.make(job())
        executor.runAll()
        assertEquals("error:load_failed:bad gguf", events.log.last())
        assertFalse(worker.isLoaded)
        assertFalse(worker.isBusy)
    }

    @Test
    fun aFailedPictureReportsTheEnginesTextAndLeavesNoFile() {
        engine.generateResult = SdNative.RESULT_ERROR
        engine.error = "out of room"
        worker.make(job("a"))
        executor.runAll()
        assertEquals("error:failed:out of room", events.log.last())
        assertFalse(File(dir, "a.png").exists())
    }

    @Test
    fun anExceptionBecomesAFailedErrorWithOnlyItsTypeAndFreesTheModel() {
        engine.throwOnGenerate = IllegalStateException("/data/user/0/secret/path")
        worker.make(job())
        executor.runAll()
        assertEquals("error:failed:IllegalStateException", events.log.last())
        assertTrue(engine.calls.contains("free"))
        assertFalse(worker.isLoaded)
        assertFalse(worker.isBusy)
    }

    @Test
    fun theModelIsFreedOnlyAfterTheIdleTime() {
        worker.make(job())
        executor.runAll()
        clock += ImagesProtocol.IDLE_FREE_MS - 1
        worker.freeIfIdle(force = false)
        executor.runAll()
        assertTrue(worker.isLoaded)
        clock += 1
        worker.freeIfIdle(force = false)
        executor.runAll()
        assertFalse(worker.isLoaded)
        assertEquals(1, engine.calls.count { it == "free" })
        // A free with nothing loaded does not call the engine again.
        worker.freeIfIdle(force = true)
        executor.runAll()
        assertEquals(1, engine.calls.count { it == "free" })
    }

    @Test
    fun lowMemoryFreesTheModelAtOnceWhenIdle() {
        worker.make(job())
        executor.runAll()
        worker.freeIfIdle(force = true)
        executor.runAll()
        assertFalse(worker.isLoaded)
    }

    @Test
    fun lowMemoryNeverFreesTheModelUnderARunningPicture() {
        engine.onGenerate = { worker.freeIfIdle(force = true) }
        worker.make(job())
        executor.runAll()
        assertEquals(listOf("load:m.gguf:4", "generate"), engine.calls)
        assertTrue(worker.isLoaded)
    }

    @Test
    fun shuttingDownStopsAPictureAndFreesTheModel() {
        worker.make(job())
        worker.shutdown()
        assertTrue(engine.calls.contains("cancel"))
        executor.runAll()
        // The job saw the cancel request after loading and never sampled; then the queued free ran.
        assertEquals(listOf("load:m.gguf:4", "free"), engine.calls.filter { it != "cancel" })
        assertEquals("cancelled", events.log.last())
    }

    @Test
    fun shuttingDownWhenIdleJustFrees() {
        worker.make(job())
        executor.runAll()
        engine.calls.clear()
        worker.shutdown()
        executor.runAll()
        assertEquals(listOf("free"), engine.calls)
    }

    @Test
    fun sizesAreMadeSafeAndThePromptStaysOutOfToString() {
        val j = job().copy(steps = 99, width = 5000, height = 3, cfg = Float.NaN).sanitized()
        assertEquals(8, j.steps)
        assertEquals(768, j.width)
        assertEquals(64, j.height)
        assertEquals(1.0f, j.cfg, 0f)
        assertFalse(j.toString().contains("secret"))
        assertFalse(j.toString().contains("gguf"))
    }

    @Test
    fun engineThreadsLeaveACoreAndStayBetweenTwoAndSix() {
        assertEquals(2, ImagesProtocol.engineThreads(1))
        assertEquals(2, ImagesProtocol.engineThreads(2))
        assertEquals(3, ImagesProtocol.engineThreads(4))
        assertEquals(6, ImagesProtocol.engineThreads(8))
        assertEquals(6, ImagesProtocol.engineThreads(32))
    }
}
