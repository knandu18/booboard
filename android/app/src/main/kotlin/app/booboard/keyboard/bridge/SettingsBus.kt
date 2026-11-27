// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.bridge

import android.content.Context
import android.content.res.Configuration
import android.os.Handler
import android.os.Looper
import android.view.inputmethod.EditorInfo

/**
 * Process-wide relay so a settings change written by one engine is announced
 * to the other. The data itself lives in files; only section names travel.
 */
internal object SettingsBus {
    private val main = Handler(Looper.getMainLooper())
    private var ime: ImeFlutterApi? = null
    private var app: AppFlutterApi? = null

    fun attachIme(api: ImeFlutterApi?) {
        main.post { ime = api }
    }

    fun attachApp(api: AppFlutterApi?) {
        main.post { app = api }
    }

    fun publish(from: EngineRole, sections: List<String>) {
        main.post {
            if (from != EngineRole.IME) ime?.onSettingsChanged(sections) {}
            if (from != EngineRole.APP) app?.onSettingsChanged(sections) {}
        }
    }
}

internal fun EditorInfo.toMessage() = EditorInfoMessage(
    inputType = inputType.toLong(),
    imeOptions = imeOptions.toLong() and 0xFFFFFFFFL,
    actionId = actionId.toLong(),
    actionLabel = actionLabel?.toString(),
    packageName = packageName,
    hintText = hintText?.toString(),
    fieldId = fieldId.toLong(),
    initialSelStart = initialSelStart.toLong(),
    initialSelEnd = initialSelEnd.toLong(),
    initialCapsMode = initialCapsMode.toLong(),
    privateImeOptions = privateImeOptions,
    contentMimeTypes = contentMimeTypes?.toList(),
)

internal fun Context.isNightMode(): Boolean =
    (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
