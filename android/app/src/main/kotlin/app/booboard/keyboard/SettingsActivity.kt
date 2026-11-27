// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard

import android.content.Intent
import app.booboard.keyboard.bridge.AppFlutterApi
import app.booboard.keyboard.bridge.AppHostApi
import app.booboard.keyboard.bridge.AppHostApiImpl
import app.booboard.keyboard.bridge.EngineRole
import app.booboard.keyboard.bridge.ImeHostApiImpl
import app.booboard.keyboard.bridge.PlatformHostApi
import app.booboard.keyboard.bridge.PlatformHostApiImpl
import app.booboard.keyboard.bridge.SettingsBus
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * The settings app (onboarding, themes, privacy center). A FragmentActivity
 * because local_auth's BiometricPrompt requires one.
 */
class SettingsActivity : FlutterFragmentActivity() {
    private var appApi: AppFlutterApi? = null

    /** Route from the launching intent, handed to Dart once (AppHostApi.takeLaunchRoute). */
    private var pendingRoute: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingRoute = intent?.getStringExtra(ImeHostApiImpl.EXTRA_ROUTE)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val api = AppFlutterApi(messenger)
        appApi = api
        PlatformHostApi.setUp(messenger, PlatformHostApiImpl(applicationContext, EngineRole.APP))
        AppHostApi.setUp(messenger, AppHostApiImpl(this) { pendingRoute.also { pendingRoute = null } })
        SettingsBus.attachApp(api)
    }

    /** The activity is already running (singleTop or CLEAR_TOP): tell Dart about the new route. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra(ImeHostApiImpl.EXTRA_ROUTE) ?: return
        appApi?.onOpenRoute(route) {}
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        SettingsBus.attachApp(null)
        appApi = null
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        PlatformHostApi.setUp(messenger, null)
        AppHostApi.setUp(messenger, null)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
