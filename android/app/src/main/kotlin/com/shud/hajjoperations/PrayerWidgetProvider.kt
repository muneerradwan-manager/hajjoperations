package com.shud.hajjoperations

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StyleSpan
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

            // A copy has just been placed. `onUpdate` draws it either way, so
            // there is nothing to render here — the one thing this is for is
            // telling the settings pane, which is sitting in the foreground
            // behind the dialog that has just closed, that its count is stale.
            ACTION_PINNED -> MainActivity.notifyWidgetPinned()
        }
    }

    /**
     * Dragged to a new size. The pane is not the same shape at every height —
     * see [NOTE_NEEDS_DP] — so a resize is a redraw, not just a relayout.
     */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        options: android.os.Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, manager, widgetId, options)
        render(context, manager, intArrayOf(widgetId))
    }

    /** The last copy has been dragged off the home screen. */
    override fun onDisabled(context: Context) {
        alarmManager(context)?.cancel(boundaryIntent(context))
    }

    companion object {
        /** Matches `PrayerWidgetBridge._channel` on the Flutter side. */
        const val CHANNEL = "com.shud.hajjoperations/prayer_widget"

        private const val ACTION_BOUNDARY = "com.shud.hajjoperations.PRAYER_BOUNDARY"

        /**
         * Fired by ANDROID, not by this app, once the reader has actually
         * confirmed the launcher's "add this widget" dialog. See [requestPin].
         */
        private const val ACTION_PINNED = "com.shud.hajjoperations.PRAYER_PINNED"

        private const val STORE = "prayer_widget"
        private const val KEY_PAYLOAD = "payload"

        /** Distinct request codes; two PendingIntents that share one are one. */
        private const val REQUEST_OPEN = 1
        private const val REQUEST_BOUNDARY = 2
        private const val REQUEST_PINNED = 3

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
         *
         * The return value says the DIALOG WAS OPENED. It does not say a widget
         * was added, and the two were being treated as the same thing — which
         * is why the settings pane still read "not added yet" after somebody had
         * just added one: the count was re-read the instant the dialog appeared,
         * seconds before there was anything new to count.
         *
         * So a third argument, which is the only honest answer to "was it
         * added": a PendingIntent Android fires ITSELF, once, after the reader
         * confirms — and never if they back out. It comes back to [onReceive]
         * below as [ACTION_PINNED].
         */
        fun requestPin(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            return manager.requestPinAppWidget(component(context), null, pinnedIntent(context))
        }

        private fun pinnedIntent(context: Context): PendingIntent =
            PendingIntent.getBroadcast(
                context,
                REQUEST_PINNED,
                Intent(context, PrayerWidgetProvider::class.java).setAction(ACTION_PINNED),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

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

            // Built per id rather than once for all of them: two copies of this
            // widget may be pinned at two different sizes, and the shorter one
            // does not get to show everything the taller one does.
            for (id in widgetIds) {
                manager.updateAppWidget(id, build(context, face, now, heightOf(manager, id)))
            }
            scheduleBoundary(context, face.next?.at)
        }

        /**
         * How tall the host is willing to draw this copy, in dp.
         *
         * The portrait minimum rather than the landscape maximum, because a
         * pane that fits only when the phone is turned sideways does not fit.
         * Hosts that report nothing get [Int.MAX_VALUE] — the declared
         * minHeight already asks for enough, and a launcher too old to answer
         * is not one to start hiding things for.
         */
        private fun heightOf(manager: AppWidgetManager, id: Int): Int {
            val options = manager.getAppWidgetOptions(id) ?: return Int.MAX_VALUE
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            return if (height <= 0) Int.MAX_VALUE else height
        }

        // ── The face ───────────────────────────────────────────────────────

        /**
         * The height, in dp, below which the sunrise-gap note is dropped.
         *
         * Something has to give on a pane squeezed shorter than its contents,
         * and a vertical LinearLayout gives up the LAST child — which is the
         * strip, the six times, the reason the thing is on the home screen. So
         * the choice is made here instead, and it goes the other way.
         *
         * The note is the affordable one. Between الشروق and الظهر the strip
         * already says nothing is due, in the way the card describes: no cell
         * wears the green that means a prayer is open, and الشروق sits back at
         * 72% besides. The note puts that into words, which is worth a row when
         * there is a row to spare and is not worth six times when there is not.
         *
         * 245 rather than the 237 the layout adds up to (the arithmetic is in
         * prayer_widget_info.xml): the eight is for a reader who has turned the
         * system font up, which makes every line here taller and is the one
         * variable none of these numbers can see.
         */
        private const val NOTE_NEEDS_DP = 245

        private fun build(
            context: Context,
            face: Face,
            now: Long,
            heightDp: Int,
        ): RemoteViews {
            val views = RemoteViews(
                context.packageName,
                if (face.rtl) R.layout.prayer_widget_rtl else R.layout.prayer_widget,
            )

            views.setOnClickPendingIntent(R.id.prayer_widget_root, openIntent(context))

            val green = context.getColor(R.color.prayer_widget_green)
            val gold = context.getColor(R.color.prayer_widget_gold)
            val muted = context.getColor(R.color.prayer_widget_muted)

            // The head of the pane. The title is set unconditionally now — it
            // used to appear only in the stale branch, which left a widget that
            // was working normally as the one surface in the app with no name
            // on it. The card has carried its own title from the beginning.
            views.setTextViewText(R.id.prayer_widget_title, face.label("title"))
            views.setInt(R.id.prayer_widget_head_icon, "setColorFilter", green)

            // The location pill. Gold, with a gps mark instead of a pin, when
            // the times were computed for مكة because no position was ever
            // taken — the same swap _LocationChip makes, off the same flag. The
            // widget was handed `approximate` in the payload and had been
            // dropping it, so approximate times looked exactly like measured
            // ones.
            val placeTone = if (face.approximate) gold else green
            // A payload that could not be read names no place, and a bordered
            // pill around an empty string is a small bright nothing in the
            // corner of the pane.
            views.setViewVisibility(
                R.id.prayer_widget_badge,
                if (face.place.isEmpty()) View.GONE else View.VISIBLE,
            )
            views.setTextViewText(R.id.prayer_widget_place, face.place)
            views.setTextColor(R.id.prayer_widget_place, placeTone)
            views.setInt(R.id.prayer_widget_badge_icon, "setColorFilter", placeTone)
            views.setImageViewResource(
                R.id.prayer_widget_badge_icon,
                if (face.approximate) {
                    R.drawable.ic_prayer_widget_gps
                } else {
                    R.drawable.ic_prayer_widget_location
                },
            )
            views.setInt(
                R.id.prayer_widget_badge,
                "setBackgroundResource",
                if (face.approximate) {
                    R.drawable.prayer_widget_badge_gold
                } else {
                    R.drawable.prayer_widget_badge_green
                },
            )

            // The two icons whose tone never changes: the coming prayer's mark
            // is always gold, the note's is always the muted ink.
            views.setInt(R.id.prayer_widget_next_icon, "setColorFilter", gold)
            views.setInt(R.id.prayer_widget_notice_icon, "setColorFilter", muted)

            if (face.next == null) {
                // Out of times: a week has gone by with the app unopened. Say so
                // — a stale row of yesterday's numbers is worse than an empty
                // one, because it looks right.
                //
                // The label, the countdown and the word under it all go: there
                // is no prayer to name, nothing to count, and "متبقي" with no
                // clock above it is a caption for a thing that is not there.
                // The rule and the strip go with them, because a rule drawn
                // across the pane with nothing beneath it is a line to nowhere.
                views.setImageViewResource(
                    R.id.prayer_widget_next_icon,
                    R.drawable.ic_prayer_widget_clock,
                )
                views.setViewVisibility(R.id.prayer_widget_label, View.GONE)
                views.setTextViewText(R.id.prayer_widget_next, "—")
                views.setViewVisibility(R.id.prayer_widget_countdown, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_remaining, View.GONE)
                note(views, face.label("stale"))
                views.setViewVisibility(R.id.prayer_widget_divider, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_strip, View.GONE)
                views.removeAllViews(R.id.prayer_widget_strip)
                return views
            }

            val next = face.next
            // الشروق is never announced as a prayer to come. Inside الفجر what
            // is running out is that prayer's own time, and the label says so —
            // the same sentence the card uses.
            views.setViewVisibility(R.id.prayer_widget_label, View.VISIBLE)
            views.setTextViewText(
                R.id.prayer_widget_label,
                if (next.slot == SLOT_SUNRISE) face.label("fajrEnds") else face.label("next"),
            )
            // The disc carries the coming mark's own icon, the way the card's
            // does — the same mapping PrayerTimesCard.iconFor makes.
            views.setImageViewResource(R.id.prayer_widget_next_icon, iconFor(next.slot))
            views.setTextViewText(
                R.id.prayer_widget_next,
                if (next.day != face.today) {
                    "${next.name} · ${next.clock} ${face.label("tomorrow")}"
                } else {
                    "${next.name} · ${next.clock}"
                },
            )

            views.setViewVisibility(R.id.prayer_widget_countdown, View.VISIBLE)
            views.setViewVisibility(R.id.prayer_widget_remaining, View.VISIBLE)
            views.setTextViewText(R.id.prayer_widget_remaining, face.label("remaining"))
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
            // words rather than colouring a prayer that is not open — but only
            // where there is a row to spare for saying it. See NOTE_NEEDS_DP.
            val inGap = face.current?.slot == SLOT_SUNRISE
            if (inGap && heightDp >= NOTE_NEEDS_DP) {
                note(views, face.label("gap"))
            } else {
                views.setViewVisibility(R.id.prayer_widget_notice_well, View.GONE)
            }

            views.removeAllViews(R.id.prayer_widget_strip)
            val marks = face.today()
            for (mark in marks) {
                views.addView(R.id.prayer_widget_strip, cell(context, mark, face))
            }
            // A payload can hold a week of marks and still have none for today —
            // the horizon starts tomorrow after a midnight refresh that has not
            // landed yet. The rule goes with the strip when that happens, for
            // the same reason it goes in the stale branch.
            val hasStrip = marks.isNotEmpty()
            val strip = if (hasStrip) View.VISIBLE else View.GONE
            views.setViewVisibility(R.id.prayer_widget_strip, strip)
            views.setViewVisibility(R.id.prayer_widget_divider, strip)
            return views
        }

        /** The well, and the one sentence in it. Hidden until there is one. */
        private fun note(views: RemoteViews, text: String) {
            views.setViewVisibility(R.id.prayer_widget_notice_well, View.VISIBLE)
            views.setTextViewText(R.id.prayer_widget_notice, text)
        }

        /**
         * The icon a mark wears, which is [PrayerTimesCard.iconFor] in Kotlin
         * and over slot NAMES rather than the enum — the payload carries
         * `slot.name`, and these six strings are that enum's own spelling.
         */
        private fun iconFor(slot: String): Int = when (slot) {
            "fajr", "maghrib" -> R.drawable.ic_prayer_widget_dawn
            SLOT_SUNRISE -> R.drawable.ic_prayer_widget_sunrise
            "dhuhr", "asr" -> R.drawable.ic_prayer_widget_noon
            "isha" -> R.drawable.ic_prayer_widget_night
            // Not reachable from a payload this app wrote. A clock is the right
            // thing for a mark whose name this version does not recognise.
            else -> R.drawable.ic_prayer_widget_clock
        }

        private fun cell(context: Context, mark: Mark, face: Face): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_cell)

            // The one rule this widget shares with the card: الشروق never wears
            // the colour that means "a prayer is open", even when the clock is
            // standing inside its window.
            val open = mark.slot == face.current?.slot && mark.prayer
            val coming = mark.slot == face.next?.slot
            val marked = open || coming

            val tone = when {
                open -> context.getColor(R.color.prayer_widget_green)
                coming -> context.getColor(R.color.prayer_widget_gold)
                else -> context.getColor(R.color.prayer_widget_muted)
            }

            // A mark that is not a prayer says so by sitting back a little, at
            // the card's own 72%. It is the quietest of the three signals that
            // keep الشروق from reading as a prayer, and the only one that is
            // still there when the clock is nowhere near it.
            views.setTextViewText(R.id.prayer_widget_cell_name, mark.name)
            views.setTextColor(
                R.id.prayer_widget_cell_name,
                if (mark.prayer) tone else fade(tone, 184),
            )

            views.setTextViewText(R.id.prayer_widget_cell_time, weighted(mark.clock, marked))
            views.setTextColor(
                R.id.prayer_widget_cell_time,
                if (marked) tone else context.getColor(R.color.prayer_widget_ink),
            )

            // Three states, three backgrounds, and none of them is `0`. See
            // prayer_widget_cell_plain.xml: an absent background is a cell 2dp
            // shorter than the two beside it that have an edge, which is
            // exactly visible across a row meant to read as one line.
            views.setInt(
                R.id.prayer_widget_cell,
                "setBackgroundResource",
                when {
                    open -> R.drawable.prayer_widget_cell_open
                    coming -> R.drawable.prayer_widget_cell_next
                    else -> R.drawable.prayer_widget_cell_plain
                },
            )
            return views
        }

        /**
         * The card sets a marked cell's time bold and a plain one's medium.
         * res/font carries two weights, so this is the bold half of that — and
         * it is a SPAN rather than a second layout because spans survive the
         * parcel a RemoteViews crosses, and a second layout would be a fourth
         * file to keep in step with this one.
         */
        private fun weighted(text: String, bold: Boolean): CharSequence {
            if (!bold) return text
            return SpannableString(text).apply {
                setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }

        /** The same colour at another alpha. */
        private fun fade(color: Int, alpha: Int): Int =
            Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))

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
            /** The times are for مكة, because no position was ever taken. */
            val approximate: Boolean,
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
                    val empty = Face(
                        rtl = false,
                        place = "",
                        approximate = false,
                        today = today,
                        now = now,
                        labels = null,
                        marks = emptyList(),
                    )
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
                            approximate = json.optBoolean("approximate", false),
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
