// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.bridge

import app.booboard.keyboard.packs.InstalledPack
import app.booboard.keyboard.packs.OfferStatus
import app.booboard.keyboard.packs.PackCheck
import app.booboard.keyboard.packs.PackManifest
import app.booboard.keyboard.packs.PackOffer

internal fun PackCheck.toMessage() = PackCheckMessage(
    id = id,
    manifestOk = manifestOk,
    missingFiles = missingFiles.toLong(),
    damagedFiles = damagedFiles.toLong(),
)

internal fun PackOffer.toMessage() = PackOfferMessage(
    id = id,
    name = name,
    sizeBytes = sizeBytes,
    status = when (status) {
        OfferStatus.NOT_REQUESTED -> PackOfferStatusMessage.NOT_REQUESTED
        OfferStatus.WAITING_FOR_NETWORK -> PackOfferStatusMessage.WAITING_FOR_NETWORK
        OfferStatus.DOWNLOADING -> PackOfferStatusMessage.DOWNLOADING
        OfferStatus.INSTALLING -> PackOfferStatusMessage.INSTALLING
        OfferStatus.FAILED -> PackOfferStatusMessage.FAILED
        OfferStatus.READY -> PackOfferStatusMessage.READY
    },
)

internal fun InstalledPack.toMessage() = PackInfoMessage(
    id = manifest.id,
    kind = when (manifest.kind) {
        PackManifest.KIND_VOICE -> PackKind.VOICE
        PackManifest.KIND_DICTIONARY -> PackKind.DICTIONARY
        PackManifest.KIND_IMAGE -> PackKind.IMAGE
        else -> PackKind.TRANSLATION
    },
    name = manifest.name,
    version = manifest.version.toLong(),
    languages = manifest.languages,
    sizeBytes = sizeBytes,
    engine = manifest.engine,
    license = manifest.license,
)
