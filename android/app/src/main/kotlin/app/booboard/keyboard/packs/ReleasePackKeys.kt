// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

/**
 * Release pack-signing public keys, as base64 X.509 SubjectPublicKeyInfo (DER). OWNER: Wave 5-C.
 *
 * The entry below is the release key generated on 2026-11-23 (SHA-256 of the DER: EC3C5B2A...DF61). Until it is replaced:
 *  - release builds trust no pack (see [PackKeys.trusted]), so packs cannot install;
 *  - `ReleasePackKeysTest` fails when the release gate runs it with BOOBOARD_RELEASE_GATE=1.
 *
 * To fill it, generate the key outside the repository (tool/release, Agent B) and paste the output of:
 *   openssl pkey -pubout -in <release-pack-key.pem> -outform DER | base64 -w0
 * Keep old keys in the list while packs signed with them are still in use (key rotation).
 */
object ReleasePackKeys {
    private const val PLACEHOLDER_PREFIX = "REPLACE"

    private val KEYS_BASE64: List<String> = listOf("MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEf5owe3nQx3Jjb/1+1LNmlwzjbIAgbv3V2vMjgweA8nN6e+ybCUbKShMUkHqAm/hD/7LaETjtgECESYWCFqVW5Q==")

    /** True while any entry is still the placeholder. */
    val hasPlaceholder: Boolean get() = KEYS_BASE64.any { it.startsWith(PLACEHOLDER_PREFIX) }

    /** The real entries (placeholders are skipped, so an unfilled list trusts nothing). */
    fun publicKeysBase64(): List<String> = KEYS_BASE64.filterNot { it.startsWith(PLACEHOLDER_PREFIX) }
}
