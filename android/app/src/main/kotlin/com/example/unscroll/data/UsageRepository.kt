package com.unscroll.app.data

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class UsageRepository(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("unscroll_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val TAG = "UsageRepository"
        
        private const val KEY_DAILY_LIMIT = "daily_limit"
        private const val KEY_TODAY_USAGE = "today_usage"
        private const val KEY_LAST_DATE = "last_date"
        private const val KEY_BLOCKED_APPS = "blocked_apps"
        private const val KEY_WEEKLY_DATA = "weekly_data"
        private const val KEY_APP_USAGE = "app_usage"
        private const val KEY_STRICT_MODE = "strict_mode"
        private const val KEY_PAUSE_UNTIL = "pause_until"

        // ⚠️ DEFAULT 1 MINUTE FOR TESTING - Change to 30 for production
        const val DEFAULT_LIMIT = 1

        @Volatile
        private var instance: UsageRepository? = null

        fun getInstance(context: Context): UsageRepository {
            return instance ?: synchronized(this) {
                instance ?: UsageRepository(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    init {
        checkAndResetDaily()
        Log.d(TAG, "Repository initialized - Limit: ${getDailyLimit()} min, Used: ${getTodayUsageMinutes()} min")
    }

    private fun getTodayDate(): String {
        return dateFormat.format(Date())
    }

    private fun checkAndResetDaily() {
        val today = getTodayDate()
        val lastDate = prefs.getString(KEY_LAST_DATE, "") ?: ""

        if (lastDate != today) {
            Log.d(TAG, "New day! Resetting usage. Last: $lastDate, Today: $today")
            
            if (lastDate.isNotEmpty()) {
                saveToWeeklyData(lastDate, prefs.getLong(KEY_TODAY_USAGE, 0L))
            }

            prefs.edit()
                .putLong(KEY_TODAY_USAGE, 0L)
                .putString(KEY_LAST_DATE, today)
                .putString(KEY_APP_USAGE, "{}")
                .apply()
        }
    }

    private fun saveToWeeklyData(date: String, usageMs: Long) {
        val weeklyJson = prefs.getString(KEY_WEEKLY_DATA, "{}") ?: "{}"
        val weekly = JSONObject(weeklyJson)
        weekly.put(date, usageMs)

        val keys = weekly.keys().asSequence().toList().sorted()
        if (keys.size > 7) {
            keys.take(keys.size - 7).forEach { weekly.remove(it) }
        }

        prefs.edit().putString(KEY_WEEKLY_DATA, weekly.toString()).apply()
    }

    // ==================== DAILY LIMIT ====================

    fun setDailyLimit(minutes: Int) {
        Log.d(TAG, "Setting daily limit: $minutes min")
        prefs.edit().putInt(KEY_DAILY_LIMIT, minutes).apply()
    }

    fun getDailyLimit(): Int {
        return prefs.getInt(KEY_DAILY_LIMIT, DEFAULT_LIMIT)
    }

    // ==================== USAGE TRACKING ====================

    fun getTodayUsageMs(): Long {
        checkAndResetDaily()
        return prefs.getLong(KEY_TODAY_USAGE, 0L)
    }

    fun getTodayUsageMinutes(): Int {
        return (getTodayUsageMs() / 60000).toInt()
    }

    fun addUsage(milliseconds: Long, appPackage: String) {
        checkAndResetDaily()

        val current = prefs.getLong(KEY_TODAY_USAGE, 0L)
        val newTotal = current + milliseconds
        prefs.edit().putLong(KEY_TODAY_USAGE, newTotal).apply()

        // Per-app usage
        val appUsageJson = prefs.getString(KEY_APP_USAGE, "{}") ?: "{}"
        val appUsage = JSONObject(appUsageJson)
        val appCurrent = appUsage.optLong(appPackage, 0L)
        appUsage.put(appPackage, appCurrent + milliseconds)
        prefs.edit().putString(KEY_APP_USAGE, appUsage.toString()).apply()
    }

    fun resetTodayUsage() {
        Log.d(TAG, "Resetting today's usage")
        prefs.edit()
            .putLong(KEY_TODAY_USAGE, 0L)
            .putString(KEY_APP_USAGE, "{}")
            .apply()
    }

    fun clearAllData() {
        Log.d(TAG, "Clearing all data")
        prefs.edit()
            .putLong(KEY_TODAY_USAGE, 0L)
            .putString(KEY_APP_USAGE, "{}")
            .putString(KEY_WEEKLY_DATA, "{}")
            .putString(KEY_LAST_DATE, getTodayDate())
            .apply()
    }

    fun isLimitReached(): Boolean {
        val used = getTodayUsageMinutes()
        val limit = getDailyLimit()
        val reached = used >= limit
        return reached
    }

    fun getRemainingMinutes(): Int {
        return maxOf(0, getDailyLimit() - getTodayUsageMinutes())
    }

    // ==================== WEEKLY DATA ====================

    fun getWeeklyUsage(): Map<String, Long> {
        val weeklyJson = prefs.getString(KEY_WEEKLY_DATA, "{}") ?: "{}"
        val weekly = JSONObject(weeklyJson)
        val result = mutableMapOf<String, Long>()

        weekly.keys().forEach { key ->
            result[key] = weekly.optLong(key, 0L)
        }

        result[getTodayDate()] = getTodayUsageMs()
        return result
    }

    // ==================== PER-APP USAGE ====================

    fun getUsageByApp(): Map<String, Long> {
        checkAndResetDaily()
        val appUsageJson = prefs.getString(KEY_APP_USAGE, "{}") ?: "{}"
        val appUsage = JSONObject(appUsageJson)
        val result = mutableMapOf<String, Long>()

        appUsage.keys().forEach { key ->
            result[key] = appUsage.optLong(key, 0L)
        }

        return result
    }

    // ==================== BLOCKED APPS ====================

    fun setBlockedApps(apps: List<String>) {
        prefs.edit().putStringSet(KEY_BLOCKED_APPS, apps.toSet()).apply()
    }

    fun getBlockedApps(): List<String> {
        val defaultApps = setOf(
            "com.instagram.android",
            "com.google.android.youtube"
        )
        return prefs.getStringSet(KEY_BLOCKED_APPS, defaultApps)?.toList() ?: defaultApps.toList()
    }

    // ==================== STRICT MODE ====================

    fun setStrictMode(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_STRICT_MODE, enabled).apply()
    }

    fun isStrictMode(): Boolean {
        return prefs.getBoolean(KEY_STRICT_MODE, false)
    }

    // ==================== PAUSE FEATURE ====================

    fun pauseUntil(timestamp: Long) {
        prefs.edit().putLong(KEY_PAUSE_UNTIL, timestamp).apply()
    }

    fun isPaused(): Boolean {
        val pauseUntil = prefs.getLong(KEY_PAUSE_UNTIL, 0L)
        return System.currentTimeMillis() < pauseUntil
    }

    fun clearPause() {
        prefs.edit().putLong(KEY_PAUSE_UNTIL, 0L).apply()
    }
}