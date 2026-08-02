package com.shud.hajjoperations

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The one activity, and the only place Flutter can reach the home-screen
 * widget.
 *
 * The widget is not a plugin and does not need to be: three calls, no
 * callbacks, no lifecycle. `applicationContext` throughout rather than `this` —
 * everything below outlives the activity, and a widget redrawn from an alarm
 * has no activity at all.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PrayerWidgetProvider.CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    val payload = call.arguments as? String
                    if (payload == null) {
                        result.error("no-payload", "update needs the JSON string", null)
                    } else {
                        PrayerWidgetProvider.store(applicationContext, payload)
                        PrayerWidgetProvider.renderAll(applicationContext)
                        result.success(null)
                    }
                }
                "count" -> result.success(
                    PrayerWidgetProvider.installedCount(applicationContext)
                )
                "pin" -> result.success(
                    PrayerWidgetProvider.requestPin(applicationContext)
                )
                else -> result.notImplemented()
            }
        }
    }
}
