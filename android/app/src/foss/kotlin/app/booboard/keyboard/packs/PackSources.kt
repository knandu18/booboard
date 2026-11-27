// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import android.content.Context

/** The foss flavour: packs are files the user imports. No Google library is on this build's classpath. */
object PackSources {
    @Suppress("UNUSED_PARAMETER")
    fun forBuild(context: Context): PackSource = FilePackSource()
}
