// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.ime

import android.content.Context
import android.graphics.drawable.Icon
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import android.view.Gravity
import android.view.ViewGroup
import android.view.inputmethod.InlineSuggestion
import android.view.inputmethod.InlineSuggestionsRequest
import android.view.inputmethod.InlineSuggestionsResponse
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.inline.InlineContentView
import android.widget.inline.InlinePresentationSpec
import androidx.annotation.RequiresApi
import androidx.autofill.inline.UiVersions
import androidx.autofill.inline.common.TextViewStyle
import androidx.autofill.inline.common.ViewStyle
import androidx.autofill.inline.v1.InlineSuggestionUi
import app.booboard.keyboard.R
import app.booboard.keyboard.bridge.RectMessage
import kotlin.math.roundToInt

/**
 * Android 11+ inline autofill: password managers hand the keyboard chips (remote views) that are
 * shown in a native overlay positioned over Dart's suggestion strip. Nothing about the suggestions
 * (labels, accounts) ever reaches Dart: only the count does.
 */
@RequiresApi(30)
internal class InlineSuggestionsController(
    private val context: Context,
    private val onCount: (Int) -> Unit,
) {
    private val main = Handler(Looper.getMainLooper())
    private val density = context.resources.displayMetrics.density

    private val row = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
    }
    private val scroller = HorizontalScrollView(context).apply {
        isHorizontalScrollBarEnabled = false
        overScrollMode = HorizontalScrollView.OVER_SCROLL_NEVER
        visibility = ViewGroup.GONE
        addView(row, FrameLayout.LayoutParams(WRAP, MATCH))
    }

    private var area: RectMessage? = null
    private var generation = 0
    private var count = 0

    /** Native view to add to the keyboard container (once per container). */
    val view: HorizontalScrollView get() = scroller

    // ---- Request ----------------------------------------------------------------

    fun createRequest(screenWidthPx: Int): InlineSuggestionsRequest {
        val styles = UiVersions.newStylesBuilder().addStyle(chipStyle()).build()
        val minSize = Size(dp(MIN_CHIP_WIDTH_DP), dp(CHIP_HEIGHT_DP))
        val maxSize = Size(maxOf(dp(MIN_CHIP_WIDTH_DP), minOf(screenWidthPx, dp(MAX_CHIP_WIDTH_DP))), dp(CHIP_HEIGHT_DP))
        val spec = InlinePresentationSpec.Builder(minSize, maxSize).setStyle(styles).build()
        return InlineSuggestionsRequest.Builder(listOf(spec))
            .setMaxSuggestionCount(MAX_SUGGESTIONS)
            .build()
    }

    /** Material 3 assist-chip look: tonal surface, 14sp label, small leading icon. */
    private fun chipStyle(): UiVersions.Style {
        val chip = ViewStyle.Builder()
            .setBackground(Icon.createWithResource(context, R.drawable.inline_chip_background))
            .setPadding(dp(12), 0, dp(12), 0)
            .build()
        val title = TextViewStyle.Builder()
            .setTextColor(context.getColor(R.color.inline_chip_text))
            .setTextSize(14f)
            .setLayoutMargin(dp(4), 0, dp(4), 0)
            .build()
        val subtitle = TextViewStyle.Builder()
            .setTextColor(context.getColor(R.color.inline_chip_subtext))
            .setTextSize(12f)
            .setLayoutMargin(dp(4), 0, dp(4), 0)
            .build()
        return InlineSuggestionUi.newStyleBuilder()
            .setChipStyle(chip)
            .setSingleIconChipStyle(chip)
            .setTitleStyle(title)
            .setSubtitleStyle(subtitle)
            .build()
    }

    // ---- Response ---------------------------------------------------------------

    fun onResponse(response: InlineSuggestionsResponse): Boolean {
        val suggestions = response.inlineSuggestions
        val gen = ++generation
        if (suggestions.isEmpty()) {
            show(emptyList())
            return true
        }
        val views = arrayOfNulls<InlineContentView>(suggestions.size)
        var pending = suggestions.size
        val finish = {
            if (gen == generation) show(views.filterNotNull())
        }
        for ((index, suggestion) in suggestions.withIndex()) {
            val done = { view: InlineContentView? ->
                views[index] = view
                if (--pending == 0) finish()
            }
            inflate(suggestion, gen, done)
        }
        return true
    }

    private fun inflate(suggestion: InlineSuggestion, gen: Int, done: (InlineContentView?) -> Unit) {
        val executor = java.util.concurrent.Executor { main.post(it) }
        val callback = java.util.function.Consumer<InlineContentView?> { view ->
            if (gen != generation) {
                done(null)
            } else {
                view?.setZOrderedOnTop(true)
                done(view)
            }
        }
        try {
            suggestion.inflate(context, Size(WRAP, WRAP), executor, callback)
        } catch (e: Exception) {
            // Some providers reject WRAP_CONTENT: retry at the spec's maximum size.
            try {
                val max = suggestion.info.inlinePresentationSpec.maxSize
                suggestion.inflate(context, max, executor, callback)
            } catch (e2: Exception) {
                Log.w(TAG, "inline inflate failed: ${e2.javaClass.simpleName}")
                done(null)
            }
        }
    }

    private fun show(views: List<InlineContentView>) {
        row.removeAllViews()
        for (v in views) {
            (v.parent as? ViewGroup)?.removeView(v)
            val lp = LinearLayout.LayoutParams(WRAP, WRAP)
            lp.marginEnd = dp(8)
            row.addView(v, lp)
        }
        val changed = count != views.size
        count = views.size
        updateVisibility()
        if (changed || views.isNotEmpty()) onCount(count)
    }

    // ---- Placement --------------------------------------------------------------

    /** Dart's suggestion-strip rect in dp, relative to the keyboard view; null hides the chips. */
    fun setArea(rect: RectMessage?) {
        area = rect
        if (rect != null) {
            val lp = (scroller.layoutParams as? FrameLayout.LayoutParams)
                ?: FrameLayout.LayoutParams(WRAP, WRAP)
            lp.gravity = Gravity.TOP or Gravity.START
            lp.leftMargin = dp(rect.left)
            lp.topMargin = dp(rect.top)
            lp.width = dp(rect.width)
            lp.height = dp(rect.height)
            scroller.layoutParams = lp
        }
        updateVisibility()
    }

    private fun updateVisibility() {
        scroller.visibility = if (area != null && count > 0) ViewGroup.VISIBLE else ViewGroup.GONE
    }

    /** Input finished (or the view is going away): drop every chip. */
    fun clear() {
        generation++
        if (count != 0 || row.childCount != 0) {
            row.removeAllViews()
            count = 0
            updateVisibility()
            onCount(0)
        }
    }

    private fun dp(value: Int) = (value * density).roundToInt()

    private fun dp(value: Double) = (value * density).roundToInt()

    private companion object {
        const val TAG = "BooBoardInline"
        const val WRAP = ViewGroup.LayoutParams.WRAP_CONTENT
        const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT
        const val CHIP_HEIGHT_DP = 40
        const val MIN_CHIP_WIDTH_DP = 96
        const val MAX_CHIP_WIDTH_DP = 280
        const val MAX_SUGGESTIONS = 6
    }
}
