package com.shud.hajjoperations

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The one activity, and the only place Flutter can reach the home-screen
 * widget and the urgent-report alarm.
 *
 * Three calls out — update, count, pin — and one call BACK, which is the whole
 * reason this class now holds onto its channel. `applicationContext`
 * throughout rather than `this`: everything the provider does outlives the
 * activity, and a widget redrawn from an alarm has no activity at all.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        alarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AlarmSound.CHANNEL,
        ).also { alarm ->
            alarm.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        AlarmSound.start(applicationContext)
                        result.success(null)
                    }
                    "stop" -> {
                        AlarmSound.stop(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PrayerWidgetProvider.CHANNEL,
        )
        widgetChannel = channel

        channel.setMethodCallHandler { call, result ->
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

    /**
     * Dropped on the way out. The engine this channel speaks over is gone by
     * the time this runs, and a stale one held in a static would be a leak of
     * the whole engine plus a call into a messenger that no longer exists.
     */
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        widgetChannel?.setMethodCallHandler(null)
        widgetChannel = null
        alarmChannel?.setMethodCallHandler(null)
        alarmChannel = null
        // The engine going away means the dialog that was ringing is gone too,
        // and a MediaPlayer looping an alarm tone with nothing left able to stop
        // it is a phone the reader has to reboot.
        AlarmSound.stop(applicationContext)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        /**
         * Null whenever no engine is attached — which is most of this app's
         * life, because the widget is drawn with the app closed.
         */
        private var widgetChannel: MethodChannel? = null

        /** Held for the same reason, and torn down in the same place. */
        private var alarmChannel: MethodChannel? = null

        /**
         * Tells Dart a copy of the widget has just been pinned.
         *
         * Called from [PrayerWidgetProvider.onReceive], which runs on the main
         * thread for a manifest-declared receiver — so this is already where a
         * MethodChannel has to be spoken to, with no hop needed.
         *
         * Silence is a correct outcome and not a failure: the reader can pin a
         * widget from the launcher's own tray with this app closed, and then
         * there is no engine to tell. The settings pane re-reads the count when
         * it is next built, which covers exactly that case.
         */
        fun notifyWidgetPinned() {
            widgetChannel?.invokeMethod("pinned", null)
        }
    }
}
