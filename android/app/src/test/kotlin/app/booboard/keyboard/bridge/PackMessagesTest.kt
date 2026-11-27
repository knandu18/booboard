// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.bridge

import app.booboard.keyboard.packs.OfferStatus
import app.booboard.keyboard.packs.InstalledPack
import app.booboard.keyboard.packs.PackCheck
import app.booboard.keyboard.packs.PackFile
import app.booboard.keyboard.packs.PackManifest
import app.booboard.keyboard.packs.PackOffer
import org.junit.Assert.assertEquals
import java.io.File
import org.junit.Test

/** The pack maintenance messages carry exactly what the store and the pack checker report. */
class PackMessagesTest {
    @Test
    fun checkKeepsCounts() {
        val m = PackCheck("translate-en-es", manifestOk = true, missingFiles = 2, damagedFiles = 3).toMessage()
        assertEquals("translate-en-es", m.id)
        assertEquals(true, m.manifestOk)
        assertEquals(2L, m.missingFiles)
        assertEquals(3L, m.damagedFiles)
    }

    @Test
    fun everyOfferStatusHasItsMessageStatus() {
        for (status in OfferStatus.values()) {
            val m = PackOffer("dict-ja-mozc", "Japanese", 7L, status).toMessage()
            assertEquals(status.name, m.status.name)
            assertEquals(7L, m.sizeBytes)
        }
    }

    @Test
    fun everyPackKindHasItsMessageKind() {
        val expected = mapOf(
            PackManifest.KIND_VOICE to PackKind.VOICE,
            PackManifest.KIND_TRANSLATION to PackKind.TRANSLATION,
            PackManifest.KIND_DICTIONARY to PackKind.DICTIONARY,
            PackManifest.KIND_IMAGE to PackKind.IMAGE,
        )
        for ((kind, message) in expected) {
            val manifest = PackManifest(
                id = "p-1",
                kind = kind,
                name = "Pack",
                version = 1,
                languages = listOf("en"),
                engine = "e",
                license = "l",
                files = listOf(PackFile("a", 1, "0".repeat(64))),
            )
            assertEquals(message, InstalledPack(manifest, File("."), 1L).toMessage().kind)
        }
    }
}
