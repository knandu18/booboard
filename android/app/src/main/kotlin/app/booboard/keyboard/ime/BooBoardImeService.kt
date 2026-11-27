// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard.ime

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InlineSuggestionsRequest
import android.view.inputmethod.InlineSuggestionsResponse
import android.view.inputmethod.InputMethodManager
import android.widget.FrameLayout
import android.widget.TextView
import androidx.annotation.RequiresApi
import androidx.core.graphics.ColorUtils
import app.booboard.keyboard.BooBoardApplication
import app.booboard.keyboard.bridge.EngineRole
import app.booboard.keyboard.bridge.ImeFlutterApi
import app.booboard.keyboard.bridge.ImeHostApi
import app.booboard.keyboard.bridge.ImeHostApiImpl
import app.booboard.keyboard.bridge.PlatformHostApi
import app.booboard.keyboard.bridge.PlatformHostApiImpl
import app.booboard.keyboard.bridge.RectMessage
import app.booboard.keyboard.bridge.SelectionMessage
import app.booboard.keyboard.bridge.SettingsBus
import app.booboard.keyboard.bridge.WindowLayoutMessage
import app.booboard.keyboard.bridge.WindowMetricsMessage
import app.booboard.keyboard.bridge.WindowMode
import app.booboard.keyboard.bridge.isNightMode
import app.booboard.keyboard.bridge.toMessage
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import kotlin.math.roundToInt

/**
 * Thin Kotlin shell around the Dart keyboard (entrypoint `keyboardMain`).
 *
 * Responsibilities: own the Flutter engine, size the input view, forward IME
 * lifecycle events to Dart, switch between docked and floating window modes,
 * overlay Android inline autofill chips, and keep a native fallback so the user
 * can always switch keyboards even if Flutter fails to draw.
 */
class BooBoardImeService : InputMethodService() {

    private var engine: FlutterEngine? = null
    private var flutterView: FlutterView? = null

    /** The previous FlutterView, kept on screen until its replacement has drawn (no flicker on mode switch). */
    private var retiredView: FlutterView? = null
    private var firstFrameListener: FlutterUiDisplayListener? = null
    private var root: KeyboardContainer? = null
    private var fallback: TextView? = null
    private var firstFrameShown = false
    private var engineRestarts = 0
    private val main = Handler(Looper.getMainLooper())

    internal var flutterApi: ImeFlutterApi? = null
        private set
    private var hostApi: ImeHostApiImpl? = null

    internal val feedback by lazy { Feedback(this) }
    private var clipboardWatcher: ClipboardWatcher? = null
    private var inline: InlineSuggestionsController? = null

    /** Total input-view height requested by Dart (dp), including the bottom inset. */
    private var contentHeightDp = DEFAULT_CONTENT_HEIGHT_DP
    internal var navBarInsetPx = 0
        private set
    internal var windowMode = WindowMode.DOCKED
        private set
    private var floatingRect: RectMessage? = null
    private var dockedWindowBackground: Drawable? = null
    private var hasDockedBackground = false

    private val fallbackCheck = Runnable {
        if (!firstFrameShown) fallback?.visibility = View.VISIBLE
    }
    private val restartCheck = Runnable {
        if (!firstFrameShown && engineRestarts < MAX_ENGINE_RESTARTS) {
            engineRestarts++
            Log.w(TAG, "no first frame, restarting engine (attempt $engineRestarts)")
            restartEngine()
        }
    }
    private val retireRunnable = Runnable { dropRetiredView() }

    override fun onCreate() {
        super.onCreate()
        startEngine()
        clipboardWatcher = ClipboardWatcher(this) { clip -> flutterApi?.onClipboardChanged(clip) {} }
            .also { it.start() }
        if (Build.VERSION.SDK_INT >= 30) {
            inline = InlineSuggestionsController(this) { count ->
                flutterApi?.onInlineSuggestionsChanged(count.toLong()) {}
            }
        }
    }

    // ---- Engine ------------------------------------------------------------------

    /** Creates (pre-warms) the keyboard engine. Returns false if it could not be started. */
    private fun startEngine(): Boolean {
        return try {
            // Creating the group initializes FlutterLoader; it must exist before
            // findAppBundlePath() is called.
            val group = (application as BooBoardApplication).engineGroup
            val entrypoint = DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "keyboardMain",
            )
            // Pre-warm: the Dart side boots while the user is still focusing a field.
            val e = group.createAndRunEngine(this, entrypoint)
            engine = e
            val messenger = e.dartExecutor.binaryMessenger
            val host = ImeHostApiImpl(this)
            hostApi = host
            ImeHostApi.setUp(messenger, host)
            PlatformHostApi.setUp(messenger, PlatformHostApiImpl(applicationContext, EngineRole.IME))
            val api = ImeFlutterApi(messenger)
            flutterApi = api
            SettingsBus.attachIme(api)
            true
        } catch (t: Throwable) {
            // The native fallback stays reachable, so the user can still switch keyboards.
            Log.e(TAG, "engine start failed: ${t.javaClass.simpleName}")
            engine = null
            flutterApi = null
            false
        }
    }

    private fun stopEngine() {
        SettingsBus.attachIme(null)
        flutterApi = null
        hostApi?.close()
        hostApi = null
        val e = engine ?: return
        engine = null
        try {
            val messenger = e.dartExecutor.binaryMessenger
            ImeHostApi.setUp(messenger, null)
            PlatformHostApi.setUp(messenger, null)
            flutterView?.detachFromFlutterEngine()
            e.destroy()
        } catch (t: Throwable) {
            Log.w(TAG, "engine stop failed: ${t.javaClass.simpleName}")
        }
    }

    /** Recovery path for a dead or wedged Dart isolate: Dart re-syncs its state through the state-sync calls. */
    private fun restartEngine() {
        stopEngine()
        if (startEngine()) {
            attachFlutterView()
            if (isInputViewShown) engine?.lifecycleChannel?.appIsResumed()
            armWatchdogs()
        } else {
            fallback?.visibility = View.VISIBLE
        }
    }

    // ---- Views -------------------------------------------------------------------

    override fun onCreateInputView(): View {
        // Called again after configuration changes: release everything held for the old view first.
        teardownInputView()
        if (engine == null) startEngine()

        val ctl = inline
        val overlay: View? = if (Build.VERSION.SDK_INT >= 30) ctl?.view else null
        val fb = buildFallback()
        val container = KeyboardContainer(this, overlay, fb)
        fallback = fb
        container.setOnApplyWindowInsetsListener { _, insets ->
            val bottom = if (Build.VERSION.SDK_INT >= 30) {
                insets.getInsets(WindowInsets.Type.navigationBars()).bottom
            } else {
                @Suppress("DEPRECATION")
                insets.systemWindowInsetBottom
            }
            // Reported in metrics only. Dart owns the total height (it adds the
            // bottom viewPadding Flutter actually applies), so the two sides can
            // never disagree about the inset.
            navBarInsetPx = bottom
            insets // not consumed: FlutterView still receives them as viewPadding
        }
        root = container
        applyWindowModeVisuals()
        attachFlutterView()
        applyHeight()
        if (engine == null) fb.visibility = View.VISIBLE
        return container
    }

    private fun teardownInputView() {
        main.removeCallbacks(retireRunnable)
        flutterView?.let { v ->
            firstFrameListener?.let { v.removeOnFirstFrameRenderedListener(it) }
            v.detachFromFlutterEngine()
        }
        retiredView?.detachFromFlutterEngine()
        if (Build.VERSION.SDK_INT >= 30) {
            inline?.let { c ->
                c.clear()
                (c.view.parent as? android.view.ViewGroup)?.removeView(c.view)
            }
        }
        root?.removeAllViews()
        flutterView = null
        retiredView = null
        firstFrameListener = null
        fallback = null
        root = null
    }

    /**
     * (Re)creates the FlutterView for the current window mode and attaches it to the engine.
     *
     * Docked uses an opaque SurfaceView (cheapest). Floating needs a transparent surface so the app shows
     * around the keyboard; a TextureView is used for that because, unlike a transparent SurfaceView, it
     * does not need setZOrderOnTop and so stays below the native overlays. The old view keeps showing its
     * last frame until the new one has drawn, so switching does not flicker.
     */
    private fun attachFlutterView() {
        val e = engine ?: return
        val container = root ?: return
        dropRetiredView()
        flutterView?.let { old ->
            firstFrameListener?.let { old.removeOnFirstFrameRenderedListener(it) }
            old.detachFromFlutterEngine()
            retiredView = old
        }
        val view = if (windowMode == WindowMode.FLOATING) {
            FlutterView(this, FlutterTextureView(this))
        } else {
            FlutterView(this, FlutterSurfaceView(this))
        }
        val listener = object : FlutterUiDisplayListener {
            override fun onFlutterUiDisplayed() {
                firstFrameShown = true
                engineRestarts = 0
                main.removeCallbacks(restartCheck)
                fallback?.visibility = View.GONE
                if (flutterView === view) dropRetiredView()
            }

            override fun onFlutterUiNoLongerDisplayed() {}
        }
        view.addOnFirstFrameRenderedListener(listener)
        firstFrameListener = listener
        flutterView = view
        firstFrameShown = false
        container.addFlutterView(view)
        view.attachToFlutterEngine(e)
        if (retiredView != null) main.postDelayed(retireRunnable, RETIRE_TIMEOUT_MS)
    }

    private fun dropRetiredView() {
        main.removeCallbacks(retireRunnable)
        retiredView?.let { root?.removeView(it) }
        retiredView = null
    }

    /** Never use the landscape full-screen "extract" editor. */
    override fun onEvaluateFullscreenMode(): Boolean = false

    // ---- Insets ------------------------------------------------------------------

    override fun onComputeInsets(outInsets: Insets) {
        super.onComputeInsets(outInsets)
        val container = root ?: return
        if (windowMode != WindowMode.FLOATING || container.height == 0) return
        // Floating: the app must not resize (insets at the very bottom of the window) and only the
        // keyboard rect takes touches; everything else in the IME window passes through.
        val windowHeight = window?.window?.decorView?.height?.takeIf { it > 0 } ?: container.height
        outInsets.contentTopInsets = windowHeight
        outInsets.visibleTopInsets = windowHeight
        outInsets.touchableInsets = Insets.TOUCHABLE_INSETS_REGION
        val origin = IntArray(2)
        container.getLocationInWindow(origin)
        val density = resources.displayMetrics.density
        val rect = floatingRect
        if (rect == null) {
            outInsets.touchableRegion.set(origin[0], origin[1], origin[0] + container.width, origin[1] + container.height)
        } else {
            outInsets.touchableRegion.set(
                origin[0] + (rect.left * density).roundToInt(),
                origin[1] + (rect.top * density).roundToInt(),
                origin[0] + ((rect.left + rect.width) * density).roundToInt(),
                origin[1] + ((rect.top + rect.height) * density).roundToInt(),
            )
        }
    }

    /** Transparent window while floating; the original window background again when docked. */
    private fun applyWindowModeVisuals() {
        val w = window?.window ?: return
        if (!hasDockedBackground) {
            dockedWindowBackground = w.decorView.background
            hasDockedBackground = true
        }
        if (windowMode == WindowMode.FLOATING) {
            w.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        } else {
            w.setBackgroundDrawable(dockedWindowBackground)
        }
    }

    /** The keyboard background where it meets the navigation bar (ARGB), sent by Dart; null until then. */
    private var navBarBackground: Int? = null

    internal fun setNavigationBarBackground(argb: Int) {
        if (navBarBackground == argb) return
        navBarBackground = argb
        applyNavBarAppearance()
    }

    /**
     * Dark navigation-bar icons on a light keyboard and light icons on a dark one (API 30+). Uses the
     * keyboard background from Dart when known, else the system night mode.
     */
    private fun applyNavBarAppearance() {
        if (Build.VERSION.SDK_INT < 30) return
        try {
            val controller = window?.window?.insetsController ?: return
            val bg = navBarBackground
            val darkBackground = if (bg != null) ColorUtils.calculateLuminance(bg) < 0.5 else isNightMode()
            val lightIcons = if (darkBackground) 0 else WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            controller.setSystemBarsAppearance(lightIcons, WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS)
        } catch (e: Exception) {
            Log.w(TAG, "nav bar appearance failed: ${e.javaClass.simpleName}")
        }
    }

    // ---- Inline autofill (Android 11+) -------------------------------------------

    @RequiresApi(Build.VERSION_CODES.R)
    override fun onCreateInlineSuggestionsRequest(uiExtras: Bundle): InlineSuggestionsRequest? =
        try {
            inline?.createRequest(resources.displayMetrics.widthPixels)
        } catch (e: Exception) {
            Log.w(TAG, "inline request failed: ${e.javaClass.simpleName}")
            null
        }

    @RequiresApi(Build.VERSION_CODES.R)
    override fun onInlineSuggestionsResponse(response: InlineSuggestionsResponse): Boolean =
        try {
            inline?.onResponse(response) ?: false
        } catch (e: Exception) {
            Log.w(TAG, "inline response failed: ${e.javaClass.simpleName}")
            false
        }

    internal fun setInlineSuggestionsArea(area: RectMessage?) {
        if (Build.VERSION.SDK_INT >= 30) inline?.setArea(area)
    }

    private fun clearInlineSuggestions() {
        if (Build.VERSION.SDK_INT >= 30) inline?.clear()
    }

    // ---- IME lifecycle -----------------------------------------------------------

    override fun onStartInput(attribute: EditorInfo, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        flutterApi?.onStartInput(attribute.toMessage(), restarting) {}
    }

    override fun onStartInputView(info: EditorInfo, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        applyNavBarAppearance()
        flutterApi?.onStartInputView(info.toMessage(), restarting) {}
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        super.onFinishInputView(finishingInput)
        flutterApi?.onFinishInputView(finishingInput) {}
    }

    override fun onFinishInput() {
        super.onFinishInput()
        clearInlineSuggestions()
        flutterApi?.onFinishInput {}
    }

    override fun onUpdateSelection(
        oldSelStart: Int, oldSelEnd: Int, newSelStart: Int, newSelEnd: Int,
        candidatesStart: Int, candidatesEnd: Int,
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        flutterApi?.onUpdateSelection(
            SelectionMessage(
                oldSelStart.toLong(), oldSelEnd.toLong(), newSelStart.toLong(), newSelEnd.toLong(),
                candidatesStart.toLong(), candidatesEnd.toLong(),
            ),
        ) {}
    }

    override fun onWindowShown() {
        super.onWindowShown()
        engine?.lifecycleChannel?.appIsResumed()
        applyNavBarAppearance()
        flutterApi?.onWindowShown {}
        if (!firstFrameShown) armWatchdogs()
    }

    override fun onWindowHidden() {
        super.onWindowHidden()
        // Inactive (not paused): Flutter draws nothing while idle, and the next
        // show needs no frame-scheduling warm-up.
        engine?.lifecycleChannel?.appIsInactive()
        flutterApi?.onWindowHidden {}
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyHeight()
        applyNavBarAppearance()
        fallback?.let { styleFallback(it) }
        flutterApi?.onConfigurationChanged(windowMetrics()) {}
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        flutterApi?.onTrimMemory(level.toLong()) {}
        if (level >= TRIM_RUNNING_LOW) {
            hostApi?.releaseNative(stopping = false)
            try {
                engine?.systemChannel?.sendMemoryPressureWarning()
            } catch (e: Exception) {
                Log.w(TAG, "memory warning failed: ${e.javaClass.simpleName}")
            }
        }
    }

    override fun onDestroy() {
        main.removeCallbacks(fallbackCheck)
        main.removeCallbacks(restartCheck)
        clipboardWatcher?.stop()
        clipboardWatcher = null
        teardownInputView()
        stopEngine()
        inline = null
        super.onDestroy()
    }

    private fun armWatchdogs() {
        main.removeCallbacks(fallbackCheck)
        main.removeCallbacks(restartCheck)
        main.postDelayed(fallbackCheck, FALLBACK_DELAY_MS)
        main.postDelayed(restartCheck, RESTART_DELAY_MS)
    }

    // ---- Called by ImeHostApiImpl ------------------------------------------------

    internal fun applyWindowLayout(layout: WindowLayoutMessage) {
        contentHeightDp = layout.heightDp.coerceIn(MIN_CONTENT_HEIGHT_DP, MAX_CONTENT_HEIGHT_DP)
        val previous = windowMode
        windowMode = layout.mode
        floatingRect = if (layout.mode == WindowMode.FLOATING) layout.floatingRect else null
        if (previous != windowMode) {
            applyWindowModeVisuals()
            attachFlutterView()
            armWatchdogs()
        }
        applyHeight()
    }

    internal fun feedbackView(): View? = root

    internal fun windowMetrics(): WindowMetricsMessage {
        val dm = resources.displayMetrics
        val config = resources.configuration
        return WindowMetricsMessage(
            screenWidthPx = dm.widthPixels.toLong(),
            screenHeightPx = dm.heightPixels.toLong(),
            density = dm.density.toDouble(),
            navigationBarInsetPx = navBarInsetPx.toLong(),
            isLandscape = config.orientation == Configuration.ORIENTATION_LANDSCAPE,
            smallestScreenWidthDp = config.smallestScreenWidthDp.toLong(),
            fontScale = config.fontScale.toDouble(),
            isNightMode = isNightMode(),
        )
    }

    private fun applyHeight() {
        val r = root ?: return
        val density = resources.displayMetrics.density
        r.fixedHeightPx = (contentHeightDp * density).roundToInt()
        // A layout pass also makes the system ask onComputeInsets again (floating rect moves).
        r.requestLayout()
    }

    private fun buildFallback(): TextView {
        val tv = TextView(this)
        tv.text = "BooBoard is starting…  Tap here to switch keyboard"
        tv.gravity = Gravity.CENTER
        tv.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        styleFallback(tv)
        tv.visibility = View.GONE
        tv.setOnClickListener {
            val switched = Build.VERSION.SDK_INT >= 28 && switchToPreviousInputMethod()
            if (!switched) {
                (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).showInputMethodPicker()
            }
        }
        return tv
    }

    /** Readable in both themes: Material 3 surface and on-surface tones. */
    private fun styleFallback(tv: TextView) {
        val night = isNightMode()
        tv.setBackgroundColor(if (night) Color.rgb(28, 27, 31) else Color.rgb(243, 237, 247))
        tv.setTextColor(if (night) Color.rgb(230, 225, 229) else Color.rgb(28, 27, 31))
    }

    /**
     * FrameLayout whose height is dictated by Dart, not by its children. Children, bottom to top:
     * Flutter view(s), the inline-autofill overlay (if any), the fallback.
     */
    private class KeyboardContainer(context: Context, overlay: View?, fallback: View) : FrameLayout(context) {
        var fixedHeightPx = 0
        private val permanentChildren: Int

        init {
            if (overlay != null) {
                (overlay.parent as? android.view.ViewGroup)?.removeView(overlay)
                addView(overlay, overlay.layoutParams as? LayoutParams ?: LayoutParams(WRAP, WRAP))
            }
            addView(fallback, LayoutParams(MATCH, MATCH))
            permanentChildren = childCount
        }

        fun addFlutterView(view: View) {
            addView(view, childCount - permanentChildren, LayoutParams(MATCH, MATCH))
        }

        override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
            super.onMeasure(widthMeasureSpec, MeasureSpec.makeMeasureSpec(fixedHeightPx, MeasureSpec.EXACTLY))
        }

        private companion object {
            const val WRAP = LayoutParams.WRAP_CONTENT
            const val MATCH = LayoutParams.MATCH_PARENT
        }
    }

    private companion object {
        const val TAG = "BooBoardIme"
        const val DEFAULT_CONTENT_HEIGHT_DP = 284.0
        const val MIN_CONTENT_HEIGHT_DP = 120.0
        const val MAX_CONTENT_HEIGHT_DP = 640.0
        const val FALLBACK_DELAY_MS = 2000L
        const val RESTART_DELAY_MS = 8000L
        const val RETIRE_TIMEOUT_MS = 400L
        const val MAX_ENGINE_RESTARTS = 2

        /** ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW (deprecated constant, still delivered by the system). */
        const val TRIM_RUNNING_LOW = 10
    }
}
