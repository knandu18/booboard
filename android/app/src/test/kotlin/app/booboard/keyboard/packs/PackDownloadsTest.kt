// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PackDownloadsTest {
    @Test
    fun publishedPackFileNamesBecomeReleaseLinks() {
        assertEquals(
            "https://github.com/knandu18/booboard/releases/latest/download/voice-parakeet-en.boopack",
            PackDownloads.urlFor("voice-parakeet-en.boopack"),
        )
    }

    @Test
    fun anythingElseIsRefused() {
        for (bad in listOf(
            "",
            "voice.zip",
            "../voice.boopack",
            "a/b.boopack",
            "https://example.com/x.boopack",
            "Voice.boopack",
            "voice.boopack?x=1",
            "-voice.boopack",
        )) {
            assertNull(bad, PackDownloads.urlFor(bad))
        }
    }
}
