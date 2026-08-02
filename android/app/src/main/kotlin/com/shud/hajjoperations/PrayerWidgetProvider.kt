package com.shud.hajjoperations

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * مواقيت الصلاة, drawn on the launcher.
 *
 * The governing fact is that this app is NOT RUNNING while the widget is on
 * screen. There is no Dart, no engine and usually no process at all — so
 * nothing here may ask a question. Everything it needs was handed over the
 * last time the app was open, as a week of finished strings (see
 * `PrayerScheduler.widgetPayload` on the Flutter side), and this class is a
 * renderer over that store and nothing more.
 *
 * Which leaves three things to get right, and they are the whole of the file:
 *
 *  * WHAT MOVES. A countdown that ticks needs no process: a [android.widget.Chronometer]
 *    counts in the launcher's own view, so the seconds run whether or not this
 *    app exists. The rest of the face changes six times a day and no oftener,
 *    which is what the boundary alarm is for.
 *  * WHICH DIRECTION. The launcher draws in the LAUNCHER's locale; the reader
 *    chose this app's. Hence two layouts — see the note in prayer_widget.xml.
 *  * WHEN IT RUNS DRY. A phone left alone for eight days has a widget with
 *    nothing left to show, and it says so rather than showing last week's
 *    times as though they were today's.
 */
class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
    ) {
        render(context, manager, widgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // The boundary alarm, a reboot (which clears every alarm this class
        // set), and the three ways the clock itself can move under it.
        when (intent.action) {
            ACTION_BOUNDARY,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            -> renderAll(context)
        }
    }

    /** The last copy has been dragged off the home screen. */
    override fun onDisabled(context: Context) {
        alarmManager(context)?.cancel(boundaryIntent(context))
    }

    companion object {
        /** Matches `PrayerWidgetBridge._channel` on the Flutter side. */
        const val CHANNEL = "com.shud.hajjoperations/prayer_widget"

        private const val ACTION_BOUNDARY = "com.shud.hajjoperations.PRAYER_BOUNDARY"
        private const val STORE = "prayer_widget"
        private const val KEY_PAYLOAD = "payload"

        /** Distinct request codes; two PendingIntents that share one are one. */
        private const val REQUEST_OPEN = 1
        private const val REQUEST_BOUNDARY = 2

        /** Keeps a week of times for the launcher to read at three in the morning. */
        fun store(context: Context, payload: String) {
            context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_PAYLOAD, payload)
                .apply()
        }

        private fun stored(context: Context): String? =
            context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
                .getString(KEY_PAYLOAD, null)

        fun component(context: Context) =
            ComponentName(context.packageName, PrayerWidgetProvider::class.java.name)

        fun installedIds(context: Context): IntArray =
            AppWidgetManager.getInstance(context).getAppWidgetIds(component(context))

        fun installedCount(context: Context): Int = installedIds(context).size

        /**
         * Android's own "add this widget" dialog, where the launcher offers one.
         * False means the reader has to long-press the home screen themselves,
         * which the app then tells them rather than showing a dead button.
         */
        fun requestPin(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            return manager.requestPinAppWidget(component(context), null, null)
        }

        fun renderAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            render(context, manager, manager.getAppWidgetIds(component(context)))
        }

        private fun render(
            context: Context,
            manager: AppWidgetManager,
            widgetIds: IntArray,
        ) {
            if (widgetIds.isEmpty()) return
            val now = System.currentTimeMillis()
            val face = Face.of(stored(context), now)

            for (id in widgetIds) {
                manager.updateAppWidget(id, build(context, face, now))
            }
            scheduleBoundary(context, face.next?.at)
        }

        // ── The face ───────────────────────────────────────────────────────

        private fun build(context: Context, face: Face, now: Long): RemoteViews {
            val views = RemoteViews(
                context.packageName,
                if (face.rtl) R.layout.prayer_widget_rtl else R.layout.prayer_widget,
            )

            views.setOnClickPendingIntent(R.id.prayer_widget_root, openIntent(context))
            views.setTextViewText(R.id.prayer_widget_place, face.place)

            if (face.next == null) {
                // Out of times: a week has gone by with the app unopened. Say so
                // — a stale row of yesterday's numbers is worse than an empty
                // one, because it looks right.
                views.setTextViewText(R.id.prayer_widget_label, face.label("title"))
                views.setTextViewText(R.id.prayer_widget_next, "—")
                views.setViewVisibility(R.id.prayer_widget_countdown, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_notice, View.VISIBLE)
                views.setTextViewText(R.id.prayer_widget_notice, face.label("stale"))
                views.removeAllViews(R.id.prayer_widget_strip)
                return views
            }

            val next = face.next
            // الشروق is never announced as a prayer to come. Inside الفجر what
            // is running out is that prayer's own time, and the label says so —
            // the same sentence the card uses.
            views.setTextViewText(
                R.id.prayer_widget_label,
                if (next.slot == SLOT_SUNRISE) face.label("fajrEnds") else face.label("next"),
            )
            views.setTextViewText(
                R.id.prayer_widget_next,
                if (next.day != face.today) {
                    "${next.name} · ${next.clock} ${face.label("tomorrow")}"
                } else {
                    "${next.name} · ${next.clock}"
                },
            )

            views.setViewVisibility(R.id.prayer_widget_countdown, View.VISIBLE)
            // The one thing here that keeps moving with nothing running: the
            // launcher's own view counts the seconds down from a base fixed in
            // elapsed-realtime, so it survives this process being killed the
            // moment after it is drawn.
            views.setChronometer(
                R.id.prayer_widget_countdown,
                SystemClock.elapsedRealtime() + (next.at - now),
                null,
                true,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                views.setChronometerCountDown(R.id.prayer_widget_countdown, true)
            }

            // Between الشروق and الظهر nothing is due, and the widget says it in
            // words rather than colouring a prayer that is not open.
            val inGap = face.current?.slot == SLOT_SUNRISE
            views.setViewVisibility(
                R.id.prayer_widget_notice,
                if (inGap) View.VISIBLE else View.GONE,
            )
            if (inGap) views.setTextViewText(R.id.prayer_widget_notice, face.label("gap"))

            views.removeAllViews(R.id.prayer_widget_strip)
            for (mark in face.today()) {
                views.addView(R.id.prayer_widget_strip, cell(context, mark, face))
            }
            return views
        }

        private fun cell(context: Context, mark: Mark, face: Face): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_cell)
            views.setTextViewText(R.id.prayer_widget_cell_name, mark.name)
            views.setTextViewText(R.id.prayer_widget_cell_time, mark.clock)

            // The one rule this widget shares with the card: الشروق never wears
            // the colour that means "a prayer is open", even when the clock is
            // standing inside its window.
            val open = mark.slot == face.current?.slot && mark.prayer
            val coming = mark.slot == face.next?.slot

            val tone = when {
                open -> context.getColor(R.color.prayer_widget_green)
                coming -> context.getColor(R.color.prayer_widget_gold)
                else -> context.getColor(R.color.prayer_widget_muted)
            }
            views.setTextColor(R.id.prayer_widget_cell_name, tone)
            views.setTextColor(
                R.id.prayer_widget_cell_time,
                if (open || coming) tone else context.getColor(R.color.prayer_widget_ink),
            )
            views.setInt(
                R.id.prayer_widget_cell,
                "setBackgroundResource",
                if (open) R.drawable.prayer_widget_cell_open else 0,
            )
            return views
        }

        // ── When it is redrawn ─────────────────────────────────────────────

        /**
         * One alarm, for the next mark of the day. Re-set every time the widget
         * is drawn, so there is never more than one outstanding.
         */
        private fun scheduleBoundary(context: Context, at: Long?) {
            val alarms = alarmManager(context) ?: return
            val intent = boundaryIntent(context)
            if (at == null) {
                alarms.cancel(intent)
                return
            }
            // A second past the boundary rather than on it, so the mark being
            // read as "next" is unambiguously the following one and not this
            // one again by a rounding of the clock. Same second of grace the
            // card's own boundary timer takes.
            val fireAt = at + 1_000
            val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                alarms.canScheduleExactAlarms()
            if (exact) {
                alarms.setExact(AlarmManager.RTC_WAKEUP, fireAt, intent)
            } else {
                // Without the permission Android may hold this for a while. The
                // countdown keeps running regardless — only the highlight and
                // the label wait, and they catch up the next time anything
                // touches the widget.
                alarms.set(AlarmManager.RTC, fireAt, intent)
            }
        }

        private fun alarmManager(context: Context): AlarmManager? =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

        private fun boundaryIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                REQUEST_BOUNDARY,
                Intent(context, PrayerWidgetProvider::class.java).setAction(ACTION_BOUNDARY),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        private fun openIntent(context: Context): PendingIntent =
            PendingIntent.getActivity(
                context,
                REQUEST_OPEN,
                context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        // ── What was handed over ───────────────────────────────────────────

        private const val SLOT_SUNRISE = "sunrise"

        private data class Mark(
            val day: String,
            val slot: String,
            val name: String,
            val clock: String,
            val at: Long,
            val prayer: Boolean,
        )

        /** Everything one drawing needs, worked out from the store once. */
        private class Face(
            val rtl: Boolean,
            val place: String,
            val today: String,
            now: Long,
            private val labels: JSONObject?,
            private val marks: List<Mark>,
        ) {
            /** The last mark already passed — the window the clock stands in. */
            val current: Mark? = marks.lastOrNull { it.at <= now }

            /** The first mark still ahead. Null once the store has run dry. */
            val next: Mark? = marks.firstOrNull { it.at > now }

            fun today(): List<Mark> = marks.filter { it.day == today }

            fun label(key: String): String = labels?.optString(key).orEmpty()

            companion object {
                fun of(payload: String?, now: Long): Face {
                    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
                    val empty = Face(false, "", today, now, null, emptyList())
                    if (payload.isNullOrEmpty()) return empty

                    return try {
                        val json = JSONObject(payload)
                        val array = json.optJSONArray("marks")
                        val marks = ArrayList<Mark>(array?.length() ?: 0)
                        for (i in 0 until (array?.length() ?: 0)) {
                            val mark = array!!.getJSONObject(i)
                            marks.add(
                                Mark(
                                    day = mark.optString("day"),
                                    slot = mark.optString("slot"),
                                    name = mark.optString("name"),
                                    clock = mark.optString("clock"),
                                    at = mark.optLong("at"),
                                    prayer = mark.optBoolean("prayer", true),
                                )
                            )
                        }
                        Face(
                            rtl = json.optBoolean("rtl", false),
                            place = json.optString("place"),
                            today = today,
                            now = now,
                            labels = json.optJSONObject("labels"),
                            // Sorted here rather than trusted from the wire: the
                            // "next mark" is the first one ahead, and that is
                            // only true of an ordered list.
                            marks = marks.sortedBy { it.at },
                        )
                    } catch (e: Exception) {
                        // A payload written by an older version of the app, or a
                        // half-written file. An empty face says "open the app",
                        // which is exactly the right instruction.
                        empty
                    }
                }
            }
        }
    }
}
