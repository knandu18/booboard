// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test

class PackKeysTest {
    private fun List<java.security.PublicKey>.containsDev(): Boolean =
        any { it.encoded.contentEquals(PackKeys.devKey().encoded) }

    @Test
    fun releaseBuildsNeverTrustTheDevKey() {
        assertFalse(PackKeys.trusted(debuggable = false).containsDev())
    }

    @Test
    fun debugBuildsTrustTheDevKeyOnTop() {
        assertTrue(PackKeys.trusted(debuggable = true).containsDev())
        assertTrue(PackKeys.trusted(debuggable = true).size == PackKeys.trusted(debuggable = false).size + 1)
    }

    @Test
    fun placeholdersAreSkippedSoAnUnfilledListTrustsNothing() {
        // Trusting nothing is the fail-closed state for release until the release key is pasted in.
        if (ReleasePackKeys.hasPlaceholder) {
            assertTrue(ReleasePackKeys.publicKeysBase64().isEmpty())
            assertTrue(PackKeys.trusted(debuggable = false).isEmpty())
        }
    }

    /**
     * Runs only in the release gate (`BOOBOARD_RELEASE_GATE=1`), so debug unit tests stay green before the
     * release key exists. The gate fails while the placeholder is in [ReleasePackKeys].
     */
    @Test
    fun releaseGateNeedsTheReleaseKeyFilledIn() {
        assumeTrue("set BOOBOARD_RELEASE_GATE=1 to run the release key check", System.getenv("BOOBOARD_RELEASE_GATE") == "1")
        assertFalse("REPLACE WITH RELEASE KEY is still in ReleasePackKeys.kt", ReleasePackKeys.hasPlaceholder)
        assertTrue(ReleasePackKeys.publicKeysBase64().isNotEmpty())
        ReleasePackKeys.publicKeysBase64().forEach { PackStore.publicKey(it) }
    }
}
