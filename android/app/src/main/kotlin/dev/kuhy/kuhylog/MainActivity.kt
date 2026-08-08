package dev.kuhy.kuhylog

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Hosts the Flutter UI and the Android half of the quick-capture bridge.
 *
 * Two directions run over one channel:
 *  - Dart calls `render` with the day summary; we cache it and repaint
 *    every placed widget.
 *  - A widget or tile tap arrives here as an intent extra, which we
 *    forward to Dart as `logTracker` or `logNote`.
 *
 * Forwarding through the activity means a capture briefly opens the app.
 * See doc/quick-capture.md for the headless-engine upgrade that removes
 * that, and why it is not done yet.
 */
class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "dev.kuhy.kuhylog/quick_capture"
        const val EXTRA_TRACKER = "dev.kuhy.kuhylog.EXTRA_TRACKER"
        const val EXTRA_NOTE = "dev.kuhy.kuhylog.EXTRA_NOTE"
    }

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "render" -> {
                    val arguments = call.arguments
                    if (arguments is Map<*, *>) {
                        QuickCaptureStore.save(
                            applicationContext,
                            JSONObject(arguments as Map<*, *>),
                        )
                        repaintWidgets()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        channel = methodChannel
        forward(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        forward(intent)
    }

    private fun forward(intent: Intent?) {
        val target = channel ?: return
        intent?.getStringExtra(EXTRA_TRACKER)?.let { tag ->
            target.invokeMethod("logTracker", mapOf("tag" to tag))
            intent.removeExtra(EXTRA_TRACKER)
        }
        intent?.getStringExtra(EXTRA_NOTE)?.let { note ->
            target.invokeMethod("logNote", mapOf("note" to note))
            intent.removeExtra(EXTRA_NOTE)
        }
    }

    private fun repaintWidgets() {
        val manager = AppWidgetManager.getInstance(applicationContext)
        val component = ComponentName(
            applicationContext,
            QuickCaptureWidget::class.java,
        )
        val ids = manager.getAppWidgetIds(component)
        if (ids.isNotEmpty()) {
            QuickCaptureWidget().onUpdate(applicationContext, manager, ids)
        }
    }
}
