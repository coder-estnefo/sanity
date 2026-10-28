package com.example.sanity

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView

/** Shown when the widget is placed so the user can pick a tracker. */
class CounterWidgetConfigActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Cancelled unless the user picks something.
        setResult(RESULT_CANCELED)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.counter_widget_config)
        val prefs = getSharedPreferences(WidgetData.PREFS_NAME, Context.MODE_PRIVATE)
        val trackers = WidgetData.loadTrackers(prefs)

        val empty = findViewById<TextView>(R.id.config_empty)
        val list = findViewById<ListView>(R.id.config_list)
        if (trackers.isEmpty()) {
            empty.text = getString(R.string.widget_no_trackers)
            list.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, emptyList<String>())
            empty.setOnClickListener { finish() }
            return
        }
        empty.text = getString(R.string.widget_choose)
        list.adapter = ArrayAdapter(
            this, android.R.layout.simple_list_item_1,
            trackers.map { "${it.name}  ·  ${it.daysFree()} days" },
        )
        list.setOnItemClickListener { _, _, position, _ ->
            val chosen = trackers[position]
            prefs.edit().putString(WidgetData.widgetKey(appWidgetId), chosen.id).apply()
            val manager = AppWidgetManager.getInstance(this)
            manager.updateAppWidget(
                appWidgetId,
                CounterWidgetProvider.buildViews(this, prefs, trackers, appWidgetId),
            )
            setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))
            finish()
        }
    }
}

