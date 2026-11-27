// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.voice

import app.booboard.keyboard.packs.InstalledPack
import app.booboard.keyboard.packs.PackManifest

/**
 * Voice typing works in English only (the Parakeet pack). OWNER: Wave 3-D.
 *
 * The keyboard shows the mic only when an English voice pack is installed and the keyboard language is
 * English ('en' or any 'en-*' variant); this side refuses every other language as well, so a Hindi
 * request is never transcribed as English.
 */
internal object VoiceLanguages {
    /** True for 'en' and every 'en-*' variant ('en-GB', 'en-IN', ...). */
    fun isEnglish(language: String?): Boolean {
        val id = language?.trim()?.lowercase() ?: return false
        return id == "en" || id.startsWith("en-")
    }

    /** True when [pack] is a voice pack that lists an English language. */
    fun isEnglishVoicePack(pack: InstalledPack): Boolean =
        pack.manifest.kind == PackManifest.KIND_VOICE && pack.manifest.languages.any(::isEnglish)
}

/**
 * Picks the voice pack for a request: none unless [language] is English; then the pack named by [packId]
 * when it is an installed English voice pack (a named pack that was deleted, or an old setting, falls back
 * to the automatic choice), else the first installed English voice pack. [open] and [list] are PackStore's
 * `open` and `list`; null when nothing fits.
 */
internal fun resolveVoicePack(
    packId: String,
    language: String?,
    open: (String) -> InstalledPack?,
    list: () -> List<InstalledPack>,
): InstalledPack? {
    if (!VoiceLanguages.isEnglish(language)) return null
    if (packId.isNotEmpty()) open(packId)?.takeIf(VoiceLanguages::isEnglishVoicePack)?.let { return it }
    return list().firstOrNull(VoiceLanguages::isEnglishVoicePack)
}
