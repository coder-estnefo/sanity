package com.example.sanity

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class CounterWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val trackers = WidgetData.loadTrackers(widgetData)
        appWidgetIds.forEach { id ->
            appWidgetManager.updateAppWidget(id, buildViews(context, widgetData, trackers, id))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Day or timezone changed: recompute the counts.
        if (intent.action == Intent.ACTION_DATE_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED
        ) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, CounterWidgetProvider::class.java))
            val prefs = context.getSharedPreferences(WidgetData.PREFS_NAME, Context.MODE_PRIVATE)
            onUpdate(context, manager, ids, prefs)
        }
    }

    companion object {
        fun buildViews(
            context: Context,
            prefs: SharedPreferences,
            trackers: List<WidgetTracker>,
            appWidgetId: Int,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.counter_widget)
            // Priority: 1) Explicitly configured ID for this widget, 2) Pinned tracker ID, 3) First tracker in list
            val chosenId = prefs.getString(WidgetData.widgetKey(appWidgetId), null)
                ?: prefs.getString(WidgetData.PINNED_TRACKER_KEY, null)
            val tracker = trackers.firstOrNull { it.id == chosenId } ?: trackers.firstOrNull()

            if (tracker == null) {
                views.setTextViewText(R.id.widget_days, "0")
                views.setTextViewText(R.id.widget_label, "days free")
                views.setTextViewText(R.id.widget_name, "Tap to add tracker")
            } else {
                val days = tracker.daysFree()
                views.setTextViewText(R.id.widget_days, days.toString())
                views.setTextViewText(
                    R.id.widget_label,
                    if (days == 1L) "day free" else "days free",
                )
                views.setTextViewText(R.id.widget_name, tracker.name)
            }

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }
            return views
        }
    }
}
