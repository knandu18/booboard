// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import java.security.PublicKey

/**
 * Public keys that may sign model packs. OWNER: Wave 5-C (pack key rotation).
 *
 * - Release builds trust [ReleasePackKeys] only. Until the release key is pasted there, they trust
 *   nothing, so no pack installs (fail closed).
 * - Debug builds also trust the development key. Its private half lives outside the repository on
 *   the developer machine (`%USERPROFILE%\.booboard\keys\pack-dev.pem`), and `tool/make_pack.dart`
 *   signs with it only when `BOOBOARD_ALLOW_DEV_KEY=1` is set.
 */
object PackKeys {
    private const val DEV_2026 =
        "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2yIInOWy82d4ORUtXVclEvy1PIiC2RL4lF8pvLIz1XRaCf+pBsWYUcW/3JnSTYGiUklDlhchYrOhCdfxyo1tZg=="

    /** The keys a [PackStore] trusts in this build. [debuggable] is true only for debug builds. */
    fun trusted(debuggable: Boolean): List<PublicKey> {
        val release = ReleasePackKeys.publicKeysBase64().map { PackStore.publicKey(it) }
        return if (debuggable) release + devKey() else release
    }

    /** The development public key (not secret). Visible to tests and to the trust-list check. */
    internal fun devKey(): PublicKey = PackStore.publicKey(DEV_2026)
}
