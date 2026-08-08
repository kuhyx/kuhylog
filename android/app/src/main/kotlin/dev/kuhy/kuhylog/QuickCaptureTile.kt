package dev.kuhy.kuhylog

import android.content.Intent
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
        startActivityAndCollapse(intent)
    }
}
