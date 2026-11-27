// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.packs

import org.json.JSONException
import org.json.JSONObject

/**
 * The signed `manifest.json` of a pack. OWNER: orchestrator.
 *
 * ```json
 * {"id": "translate-en-es", "kind": "translation", "name": "English → Spanish", "version": 1,
 *  "languages": ["en", "es"], "engine": "opus-mt-onnx", "license": "CC-BY-4.0",
 *  "files": [{"path": "model/encoder.onnx", "size": 1234, "sha256": "<64 hex>"}]}
 * ```
 * `kind` is `voice`, `translation`, `dictionary` or `image`. For translation, `languages` is exactly `[from, to]`.
 * Paths use `/`, letters, digits, `.`, `_` and `-` only, never `..`.
 */
data class PackManifest(
    val id: String,
    val kind: String,
    val name: String,
    val version: Int,
    val languages: List<String>,
    val engine: String,
    val license: String,
    val files: List<PackFile>,
) {
    companion object {
        const val KIND_VOICE = "voice"
        const val KIND_TRANSLATION = "translation"

        /** Wave 4: Chinese/Japanese conversion data, read by Dart from the pack folder. */
        const val KIND_DICTIONARY = "dictionary"

        /** Images: the picture model (GGUF) and its fast decoder, read by the `:images` helper process. */
        const val KIND_IMAGE = "image"
        private const val MAX_FILES = 64
        private val PATH_RE = Regex("[A-Za-z0-9_-][A-Za-z0-9._-]*(/[A-Za-z0-9_-][A-Za-z0-9._-]*)*")
        private val HEX_RE = Regex("[0-9a-f]{64}")
        private val LANG_RE = Regex("[a-z]{2,3}(-[A-Za-z0-9]{2,8})?")

        fun parse(bytes: ByteArray): PackManifest = try {
            val j = JSONObject(String(bytes, Charsets.UTF_8))
            val langs = j.getJSONArray("languages")
            val files = j.getJSONArray("files")
            if (files.length() !in 1..MAX_FILES) throw PackException("bad_format", "file count")
            val m = PackManifest(
                id = j.getString("id"),
                kind = j.getString("kind"),
                name = j.getString("name"),
                version = j.getInt("version"),
                languages = List(langs.length()) { langs.getString(it) },
                engine = j.getString("engine"),
                license = j.getString("license"),
                files = List(files.length()) {
                    val f = files.getJSONObject(it)
                    PackFile(f.getString("path"), f.getLong("size"), f.getString("sha256").lowercase())
                },
            )
            m.validate()
            m
        } catch (e: JSONException) {
            throw PackException("bad_format", "manifest: ${e.javaClass.simpleName}")
        }
    }

    private fun validate() {
        fun fail(what: String): Nothing = throw PackException("bad_format", what)
        if (!PackStore.ID_RE.matches(id)) fail("id")
        if (kind != KIND_VOICE && kind != KIND_TRANSLATION && kind != KIND_DICTIONARY && kind != KIND_IMAGE) fail("kind")
        if (version < 1) fail("version")
        if (languages.isEmpty() || languages.any { !LANG_RE.matches(it) }) fail("languages")
        if (kind == KIND_TRANSLATION && languages.size != 2) fail("translation languages")
        val seen = HashSet<String>()
        for (f in files) {
            if (!PATH_RE.matches(f.path) || f.path.split('/').any { it == ".." || it == "." }) fail("path")
            if (f.path == PackStore.MANIFEST || f.path == PackStore.SIGNATURE) fail("reserved path")
            if (!seen.add(f.path)) fail("duplicate path")
            if (f.size < 0) fail("size")
            if (!HEX_RE.matches(f.sha256)) fail("sha256")
        }
        // A file "a" and a file "a/b" cannot both exist: the second write would fail with an untyped error (SEC-05).
        if (seen.any { p -> seen.any { other -> other.startsWith("$p/") } }) fail("path is a prefix of another path")
    }
}

data class PackFile(val path: String, val size: Long, val sha256: String)
