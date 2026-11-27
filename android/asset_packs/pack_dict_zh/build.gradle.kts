// SPDX-License-Identifier: GPL-3.0-or-later
//
// Play on-demand asset pack "pack_dict_zh" (Wave 5-C). It carries the signed pack "dict-zh-rime-ice.boopack",
// copied into src/main/assets/ by tool/packs/copy_asset_packs.ps1. The copy is never committed.
// Only the play flavour uses it (see docs/release/asset-packs.md).
plugins {
    id("com.android.asset-pack")
}

assetPack {
    packName = "pack_dict_zh"
    dynamicDelivery {
        deliveryType = "on-demand"
    }
}
