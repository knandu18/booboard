// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

/**
 * Where published packs are downloaded from. BooBoard has no internet permission: it only hands this link
 * to the user's browser, which does the download. The URL is always built here from a plain pack file name,
 * so the settings app can never be asked to open any other address.
 */
object PackDownloads {
    /** The project's latest GitHub release; each pack is one asset of it. */
    const val RELEASE_DOWNLOAD_BASE = "https://github.com/knandu18/booboard/releases/latest/download/"

    private val FILE_NAME = Regex("^[a-z0-9][a-z0-9-]{0,62}\\.boopack$")

    /** The download link for [fileName], or null when it is not a plain .boopack file name. */
    fun urlFor(fileName: String): String? = if (FILE_NAME.matches(fileName)) RELEASE_DOWNLOAD_BASE + fileName else null
}
