// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.images

import app.booboard.keyboard.bridge.ImageEventKind
import java.io.File
import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ImagesSupportTest {
    private fun tempDir() = Files.createTempDirectory("images").toFile()

    @Test
    fun onlyArm64AndX86_64HaveAnEngine() {
        assertTrue(ImagesAbi.supported("arm64-v8a"))
        assertTrue(ImagesAbi.supported("x86_64"))
        assertFalse(ImagesAbi.supported("armeabi-v7a"))
        assertFalse(ImagesAbi.supported("x86"))
        assertFalse(ImagesAbi.supported(null))
    }

    @Test
    fun theImagePackNeedsBothModelFiles() {
        val dir = tempDir()
        assertNull(ImagesPack.files(dir))
        File(dir, "model").mkdirs()
        File(dir, ImagesPack.MODEL).writeBytes(byteArrayOf(1))
        assertNull(ImagesPack.files(dir))
        File(dir, ImagesPack.TAESD).writeBytes(byteArrayOf(2))
        val files = ImagesPack.files(dir)
        assertNotNull(files)
        assertEquals(File(dir, "model/model.gguf").path, files!!.modelPath)
        assertEquals(File(dir, "model/taesd.safetensors").path, files.taesdPath)
    }

    @Test
    fun keepsOnlyTheLastFivePicturesIncludingTheNewOne() {
        val dir = tempDir()
        for (i in 1..7) {
            File(dir, "$i.png").apply {
                writeBytes(byteArrayOf(1))
                setLastModified(1_000L * i)
            }
        }
        File(dir, "left-over.tmp").writeBytes(byteArrayOf(1))
        val out = ImagesFiles.newOutput(dir, 99_000L)
        assertEquals("99000.png", out.name)
        assertEquals(dir, out.parentFile)
        val kept = dir.list()!!.sorted()
        // The four newest old pictures stay; the new one is made by the engine.
        assertEquals(listOf("4.png", "5.png", "6.png", "7.png"), kept)
    }

    @Test
    fun aNewOutputNeverReusesAName() {
        val dir = tempDir()
        File(dir, "5.png").writeBytes(byteArrayOf(1))
        assertEquals("5-1.png", ImagesFiles.newOutput(dir, 5).name)
    }

    @Test
    fun aMissingFolderIsCreated() {
        val dir = File(tempDir(), "images")
        ImagesFiles.newOutput(dir, 1)
        assertTrue(dir.isDirectory)
    }

    @Test
    fun repliesBecomeEvents() {
        val loading = ImageReplies.toEvent(ImagesProtocol.MSG_PROGRESS, phase = ImagesProtocol.PHASE_LOADING)!!
        assertEquals(ImageEventKind.LOADING, loading.kind)
        val step = ImageReplies.toEvent(ImagesProtocol.MSG_PROGRESS, phase = ImagesProtocol.PHASE_SAMPLING, step = 2, steps = 4)!!
        assertEquals(ImageEventKind.STEP, step.kind)
        assertEquals(2L, step.step)
        assertEquals(4L, step.steps)
        val decoding = ImageReplies.toEvent(ImagesProtocol.MSG_PROGRESS, phase = ImagesProtocol.PHASE_DECODING)!!
        assertEquals(ImageEventKind.DECODING, decoding.kind)
        val done = ImageReplies.toEvent(ImagesProtocol.MSG_DONE, path = "/c/images/1.png", millis = 1234)!!
        assertEquals(ImageEventKind.DONE, done.kind)
        assertEquals("/c/images/1.png", done.path)
        assertEquals(1234L, done.millis)
        assertEquals(ImageEventKind.CANCELLED, ImageReplies.toEvent(ImagesProtocol.MSG_CANCELLED)!!.kind)
        val error = ImageReplies.toEvent(ImagesProtocol.MSG_ERROR, code = "load_failed")!!
        assertEquals(ImageEventKind.ERROR, error.kind)
        assertEquals("load_failed", error.error)
    }

    @Test
    fun oddRepliesNeverCrashTheKeyboard() {
        assertNull(ImageReplies.toEvent(ImagesProtocol.MSG_PROGRESS, phase = 7))
        assertNull(ImageReplies.toEvent(999))
        assertEquals("failed", ImageReplies.toEvent(ImagesProtocol.MSG_ERROR)!!.error)
        assertEquals("failed", ImageReplies.toEvent(ImagesProtocol.MSG_DONE)!!.error)
    }

    @Test
    fun onlyTheEndingEventsAreFinal() {
        assertTrue(ImageReplies.isFinal(ImageReplies.toEvent(ImagesProtocol.MSG_DONE, path = "p")!!))
        assertTrue(ImageReplies.isFinal(ImageReplies.toEvent(ImagesProtocol.MSG_CANCELLED)!!))
        assertTrue(ImageReplies.isFinal(ImageReplies.toEvent(ImagesProtocol.MSG_ERROR, code = "x")!!))
        assertFalse(ImageReplies.isFinal(ImageReplies.toEvent(ImagesProtocol.MSG_PROGRESS)!!))
    }
}
