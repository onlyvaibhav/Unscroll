package com.unscroll.app.channels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.unscroll.app.services.ReelsMonitorService
import com.unscroll.app.data.UsageRepository
import android.os.PowerManager 

class BlockerMethodChannel {

    companion object {
        private const val METHOD_CHANNEL = "com.unscroll.app/methods"
        private const val EVENT_CHANNEL = "com.unscroll.app/events"

        fun register(activity: Activity, flutterEngine: FlutterEngine) {
            val usageRepository = UsageRepository.getInstance(activity)

            // Method Channel for commands
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                METHOD_CHANNEL
            ).setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        // ========== PERMISSIONS ==========
                         "isIgnoringBatteryOptimizations" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val pm = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
                                result.success(pm.isIgnoringBatteryOptimizations(activity.packageName))
                            } else {
                                result.success(true) // Old versions don't have this strict optimization
                            }
                        }
                        "requestIgnoreBatteryOptimizations" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                try {
                                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                    intent.data = Uri.parse("package:${activity.packageName}")
                                    activity.startActivity(intent)
                                    result.success(true)
                                } catch (e: Exception) {
                                    // Fallback if direct intent fails
                                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                    activity.startActivity(intent)
                                    result.success(false)
                                }
                            } else {
                                result.success(true)
                            }
                        }
                        "isAccessibilityEnabled" -> {
                            result.success(isAccessibilityServiceEnabled(activity))
                        }
                        "openAccessibilitySettings" -> {
                            openAccessibilitySettings(activity)
                            result.success(true)
                        }
                        "hasOverlayPermission" -> {
                            result.success(hasOverlayPermission(activity))
                        }
                        "requestOverlayPermission" -> {
                            requestOverlayPermission(activity)
                            result.success(true)
                        }

                        // ========== DAILY LIMIT ==========
                        "setDailyLimit" -> {
                            val minutes = call.argument<Int>("minutes") ?: 30
                            usageRepository.setDailyLimit(minutes)
                            ReelsMonitorService.updateSettings()
                            result.success(true)
                        }
                        "getDailyLimit" -> {
                            result.success(usageRepository.getDailyLimit())
                        }

                        // ========== USAGE DATA ==========
                        "getTodayUsage" -> {
                            result.success(usageRepository.getTodayUsageMs())
                        }
                        "getTodayUsageMinutes" -> {
                            result.success(usageRepository.getTodayUsageMinutes())
                        }
                        "getWeeklyUsage" -> {
                            val weekly = usageRepository.getWeeklyUsage()
                            result.success(weekly.mapValues { it.value.toInt() })
                        }
                        "getUsageByApp" -> {
                            val byApp = usageRepository.getUsageByApp()
                            result.success(byApp.mapValues { it.value.toInt() })
                        }
                        "resetTodayUsage" -> {
                            usageRepository.resetTodayUsage()
                            result.success(true)
                        }
                        "clearAllData" -> {
                            usageRepository.clearAllData()
                            result.success(true)
                        }

                        // ========== BLOCKED APPS ==========
                        "setBlockedApps" -> {
                            val apps = call.argument<List<String>>("apps") ?: listOf()
                            usageRepository.setBlockedApps(apps)
                            ReelsMonitorService.updateSettings()
                            result.success(true)
                        }
                        "getBlockedApps" -> {
                            result.success(usageRepository.getBlockedApps())
                        }

                        // ========== SERVICE STATUS ==========
                        "isServiceRunning" -> {
                            result.success(ReelsMonitorService.isRunning)
                        }

                        // ========== STRICT MODE ==========
                        "setStrictMode" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            usageRepository.setStrictMode(enabled)
                            result.success(true)
                        }
                        "isStrictMode" -> {
                            result.success(usageRepository.isStrictMode())
                        }

                        // ========== PAUSE FEATURE ==========
                        "pauseFor" -> {
                            val minutes = call.argument<Int>("minutes") ?: 5
                            val until = System.currentTimeMillis() + (minutes * 60 * 1000L)
                            usageRepository.pauseUntil(until)
                            ReelsMonitorService.updateSettings()
                            result.success(true)
                        }
                        "isPaused" -> {
                            result.success(usageRepository.isPaused())
                        }
                        "clearPause" -> {
                            usageRepository.clearPause()
                            ReelsMonitorService.updateSettings()
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, e.stackTraceToString())
                }
            }

            // Event Channel for real-time updates
            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                EVENT_CHANNEL
            ).setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    ReelsMonitorService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    ReelsMonitorService.eventSink = null
                }
            })
        }

        private fun isAccessibilityServiceEnabled(context: Context): Boolean {
            val expectedName = "${context.packageName}/.services.ReelsMonitorService"
            val altName = "${context.packageName}/com.unscroll.app.services.ReelsMonitorService"

            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            return enabledServices.contains(expectedName) ||
                    enabledServices.contains(altName) ||
                    enabledServices.contains("ReelsMonitorService")
        }

        private fun openAccessibilitySettings(activity: Activity) {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            activity.startActivity(intent)
        }

        private fun hasOverlayPermission(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(context)
            } else true
        }

        private fun requestOverlayPermission(activity: Activity) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}")
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                activity.startActivity(intent)
            }
        }
    }
}