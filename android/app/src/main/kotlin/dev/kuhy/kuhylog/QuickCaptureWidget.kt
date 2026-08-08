package dev.kuhy.kuhylog

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * A four-button home-screen widget: today's score plus the first four
 * visible trackers, each a one-tap capture.
 */
class QuickCaptureWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val summary = QuickCaptureStore.load(context)
        val trackers = QuickCaptureStore.trackers(summary)
        val score = summary.optInt("score", 0)

        val views = RemoteViews(context.packageName, R.layout.widget_quick_capture)
        views.setTextViewText(
            R.id.widget_score,
            if (score >= 0) "today +$score" else "today $score",
        )

        val slots = listOf(
            R.id.widget_slot_0,
            R.id.widget_slot_1,
            R.id.widget_slot_2,
            R.id.widget_slot_3,
        )
        slots.forEachIndexed { index, slotId ->
            val tracker = trackers.getOrNull(index)
            if (tracker == null) {
                views.setTextViewText(slotId, "")
                views.setOnClickPendingIntent(slotId, null)
            } else {
                val tag = tracker.optString("tag")
                views.setTextViewText(
                    slotId,
                    "${tracker.optString("glyph")}\n${tracker.optString("display")}",
                )
                views.setOnClickPendingIntent(slotId, captureIntent(context, tag))
            }
        }

        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }

    private fun captureIntent(context: Context, tag: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "$ACTION_CAPTURE.$tag"
            putExtra(MainActivity.EXTRA_TRACKER, tag)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            tag.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    companion object {
        private const val ACTION_CAPTURE = "dev.kuhy.kuhylog.CAPTURE"
    }
}
