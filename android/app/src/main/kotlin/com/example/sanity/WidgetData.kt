package com.example.sanity

import android.content.SharedPreferences
import org.json.JSONArray
import java.time.LocalDate
import java.time.temporal.ChronoUnit

data class WidgetTracker(val id: String, val name: String, val quitDate: LocalDate) {
    /** Calendar days since quit date, never negative. */
    fun daysFree(today: LocalDate = LocalDate.now()): Long =
        maxOf(0L, ChronoUnit.DAYS.between(quitDate, today))
}

object WidgetData {
    const val PREFS_NAME = "HomeWidgetPreferences"
    private const val TRACKERS_KEY = "trackers"
    const val PINNED_TRACKER_KEY = "pinned_tracker_id"

    fun widgetKey(appWidgetId: Int) = "widget_$appWidgetId"

    fun loadTrackers(prefs: SharedPreferences): List<WidgetTracker> {
        val raw = prefs.getString(TRACKERS_KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map {
                val o = arr.getJSONObject(it)
                WidgetTracker(
                    o.getString("id"),
                    o.getString("name"),
                    LocalDate.parse(o.getString("quitDate")),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
