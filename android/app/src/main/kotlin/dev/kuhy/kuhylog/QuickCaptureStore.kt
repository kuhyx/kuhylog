package dev.kuhy.kuhylog

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * The last summary Dart published, cached so a home-screen widget can
 * paint itself while the app is not running.
 *
 * Deliberately a dumb cache: it never computes anything. Dart owns every
 * number here, which keeps the two halves from disagreeing about what
 * "today" means across a timezone change.
 */
object QuickCaptureStore {
    private const val PREFS = "kuhylog.quick_capture"
    private const val KEY_SUMMARY = "summary"

    fun save(context: Context, summary: JSONObject) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_SUMMARY, summary.toString())
            .apply()
    }

    fun load(context: Context): JSONObject {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_SUMMARY, null) ?: return empty()
        return try {
            JSONObject(raw)
        } catch (error: Exception) {
            empty()
        }
    }

    fun trackers(summary: JSONObject): List<JSONObject> {
        val array: JSONArray = summary.optJSONArray("trackers") ?: JSONArray()
        return (0 until array.length()).mapNotNull { array.optJSONObject(it) }
    }

    private fun empty(): JSONObject = JSONObject()
        .put("score", 0)
        .put("entries", 0)
        .put("trackers", JSONArray())
}
