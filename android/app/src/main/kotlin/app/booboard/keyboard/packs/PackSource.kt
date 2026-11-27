// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import java.io.InputStream

/**
 * Where packs come from. OWNER: Wave 5-C.
 *
 * The keyboard never downloads anything. In the `play` flavour, Google Play delivers some packs as
 * on-demand asset packs ([PlayAssetPackSource], see docs/release/asset-packs.md). Whatever the source,
 * a pack reaches the phone only through [DeliveredPacks.install], which runs the same signature and hash
 * checks as a file the user imports. The store's copy is never trusted on its own.
 */
interface PackSource {
    /** True when the store delivers some packs in this build (play). False for import-only builds (foss). */
    val storeDelivered: Boolean

    /** The packs the store can deliver, with their state. Empty when [storeDelivered] is false. */
    fun offers(): List<PackOffer>

    /** Asks the store to deliver pack [id]. Returns at once; progress arrives through [offers]. */
    fun request(id: String)

    /** The delivered `.boopack` file for [id], or null when it is not there yet. The caller closes it. */
    fun openDelivered(id: String): InputStream?

    /** Tells the store it may remove its copy of [id]. Called only after a verified install. */
    fun release(id: String)
}

/** A pack the store can deliver. [sizeBytes] is the download size Play reports, or the catalogue estimate. */
data class PackOffer(val id: String, val name: String, val sizeBytes: Long, val status: OfferStatus)

/** Where a store delivery stands. Mirrored by `PackOfferStatus` in lib/src/packs/pack_maintenance.dart. */
enum class OfferStatus { NOT_REQUESTED, WAITING_FOR_NETWORK, DOWNLOADING, INSTALLING, FAILED, READY }

/**
 * The packs this app can get through a store, with the asset-pack names used in the Gradle modules
 * under android/asset_packs/. Asset pack names must be lowercase letters, digits and underscores.
 */
object StoreCatalog {
    data class Entry(val id: String, val packName: String, val displayName: String, val expectedBytes: Long)

    val entries: List<Entry> = listOf(
        Entry("dict-zh-rime-ice", "pack_dict_zh", "Chinese (Simplified) dictionary", 38_052_532L),
        Entry("dict-ja-mozc", "pack_dict_ja", "Japanese dictionary (Mozc)", 20_267_770L),
        Entry("translate-en-es", "pack_translate_en_es", "English → Spanish", 115_635_262L),
    )

    fun byId(id: String): Entry? = entries.firstOrNull { it.id == id }
}

/** Import-only source: the foss flavour. `PackSources.forBuild` lives in each flavour's source set. */
class FilePackSource : PackSource {
    override val storeDelivered: Boolean get() = false
    override fun offers(): List<PackOffer> = emptyList()
    override fun request(id: String): Unit = throw UnsupportedOperationException("packs are imported from a file")
    override fun openDelivered(id: String): InputStream? = null
    override fun release(id: String) = Unit
}

object DeliveredPacks {
    /**
     * Installs the store's copy of [id] through [store], with the same checks as an imported file, then
     * asks the store to drop its copy. Returns null when the store has not delivered the pack yet.
     * Throws [PackException] when the copy fails verification; the store's copy is then kept.
     */
    fun install(source: PackSource, store: PackStore, id: String): InstalledPack? {
        val input = source.openDelivered(id) ?: return null
        val installed = input.use { store.install(it) }
        source.release(id)
        return installed
    }
}
