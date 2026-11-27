// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import android.content.Context

/** The play flavour: Google Play delivers the large packs; the keyboard still verifies each one itself. */
object PackSources {
    @Volatile
    private var source: PackSource? = null

    /** One source per process: it holds the Play state listener. */
    fun forBuild(context: Context): PackSource =
        source ?: synchronized(this) { source ?: PlayAssetPackSource(context).also { source = it } }
}
