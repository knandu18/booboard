// SPDX-License-Identifier: GPL-3.0-or-later
package app.booboard.keyboard

import android.app.Application
import io.flutter.embedding.engine.FlutterEngineGroup

class BooBoardApplication : Application() {
    /**
     * One engine group for the whole process, so the keyboard engine and the
     * settings engine share the Dart VM snapshot and GPU context.
     */
    val engineGroup: FlutterEngineGroup by lazy { FlutterEngineGroup(this) }
}
