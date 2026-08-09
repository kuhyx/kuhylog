package dev.kuhy.kuhylog

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * A quick-settings tile showing today's score, which on tap captures the
 * first tracker in the summary.
 */
class QuickCaptureTile : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        val summary = QuickCaptureStore.load(applicationContext)
        val score = summary.optInt("score", 0)
        qsTile?.apply {
            label = if (score >= 0) "kuhylog +$score" else "kuhylog $score"
            state = Tile.STATE_ACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        super.onClick()
        val trackers = QuickCaptureStore.trackers(
            QuickCaptureStore.load(applicationContext),
        )
        val tag = trackers.firstOrNull()?.optString("tag") ?: return
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_TRACKER, tag)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        // The Intent overload of startActivityAndCollapse throws
        // UnsupportedOperationException from API 34 on, so wrap it. The
        // PendingIntent must be mutable: the system fills in the launch
        // display before dispatching it.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    applicationContext,
                    tag.hashCode(),
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_MUTABLE,
                ),
            )
        } else {
            startActivityAndCollapse(intent)
        }
    }
}
