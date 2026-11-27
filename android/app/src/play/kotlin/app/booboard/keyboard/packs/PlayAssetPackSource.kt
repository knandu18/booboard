// SPDX-License-Identifier: GPL-3.0-or-later
//
// PLAY FLAVOUR ONLY (src/play). OWNER: Wave 5-C. Compiled against com.google.android.play:asset-delivery 2.3.0.
// Play delivers the asset packs; DeliveredPacks.install verifies the .boopack before it is trusted.
package app.booboard.keyboard.packs

import android.content.Context
import com.google.android.play.core.assetpacks.AssetPackManager
import com.google.android.play.core.assetpacks.AssetPackManagerFactory
import com.google.android.play.core.assetpacks.AssetPackState
import com.google.android.play.core.assetpacks.AssetPackStateUpdateListener
import com.google.android.play.core.assetpacks.AssetPackStates
import com.google.android.play.core.assetpacks.model.AssetPackStatus
import com.google.android.gms.tasks.Task
import java.io.File
import java.io.InputStream
import java.util.concurrent.ConcurrentHashMap

/**
 * Packs delivered by Google Play as on-demand asset packs. Play downloads them (the keyboard has no
 * network); this class only asks Play for them, reports their state and hands the `.boopack` file to
 * [DeliveredPacks.install], which verifies it. The keyboard's own copy is then installed by [PackStore].
 */
class PlayAssetPackSource(context: Context) : PackSource {
    private val manager: AssetPackManager = AssetPackManagerFactory.getInstance(context.applicationContext)
    private val states = ConcurrentHashMap<String, AssetPackState>()

    private val listener = AssetPackStateUpdateListener { state -> states[state.name()] = state }

    init {
        manager.registerListener(listener)
    }

    override val storeDelivered: Boolean get() = true

    private fun remember(task: Task<AssetPackStates>) {
        task.addOnSuccessListener { result -> states.putAll(result.packStates()) }
    }

    /** Reads what Play knows now (the listener only reports changes); the answer lands before the next read. */
    override fun offers(): List<PackOffer> = refreshed().let { _ -> currentOffers() }

    private fun refreshed() = remember(manager.getPackStates(StoreCatalog.entries.map { it.packName }))

    private fun currentOffers(): List<PackOffer> = StoreCatalog.entries.map { entry ->
        val state = states[entry.packName]
        PackOffer(
            id = entry.id,
            name = entry.displayName,
            sizeBytes = state?.totalBytesToDownload()?.takeIf { it > 0 } ?: entry.expectedBytes,
            status = offerStatus(state),
        )
    }

    /** Asks Play to deliver the pack. Play requires the app to be in the foreground for this call. */
    override fun request(id: String) {
        val entry = StoreCatalog.byId(id) ?: throw IllegalArgumentException("not a store pack")
        remember(manager.fetch(listOf(entry.packName)))
    }

    /** The `.boopack` the asset pack carries (src/main/assets/<id>.boopack), or null until Play has it. */
    override fun openDelivered(id: String): InputStream? {
        val entry = StoreCatalog.byId(id) ?: return null
        val folder = manager.getPackLocation(entry.packName)?.assetsPath() ?: return null
        return File(folder, "$id.boopack").takeIf { it.isFile }?.inputStream()
    }

    /** Asks Play to remove its copy. Play may refuse or ignore this; the keyboard's copy is already verified. */
    override fun release(id: String) {
        val entry = StoreCatalog.byId(id) ?: return
        manager.removePack(entry.packName)
    }

    private fun offerStatus(state: AssetPackState?): OfferStatus = when (state?.status()) {
        null, AssetPackStatus.NOT_INSTALLED -> OfferStatus.NOT_REQUESTED
        AssetPackStatus.PENDING, AssetPackStatus.DOWNLOADING, AssetPackStatus.TRANSFERRING -> OfferStatus.DOWNLOADING
        AssetPackStatus.WAITING_FOR_WIFI, AssetPackStatus.REQUIRES_USER_CONFIRMATION -> OfferStatus.WAITING_FOR_NETWORK
        // Play has finished: the file is there and the keyboard still has to verify and install it.
        AssetPackStatus.COMPLETED -> OfferStatus.READY
        AssetPackStatus.FAILED, AssetPackStatus.CANCELED -> OfferStatus.FAILED
        else -> OfferStatus.NOT_REQUESTED
    }
}
