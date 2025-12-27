package com.unscroll.app.services

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.TextView
import io.flutter.plugin.common.EventChannel
import com.unscroll.app.R
import com.unscroll.app.data.UsageRepository

class ReelsMonitorService : AccessibilityService() {

    companion object {
        private const val TAG = "UnscrollService"
        private const val DEBUG = true
        
        // ============ CONFIG ============
        private const val MAX_SILENT_REDIRECTS = 3
        private const val CHECK_INTERVAL_MS = 1000L  // Check every 1 second
        private const val REDIRECT_COOLDOWN_MS = 2500L  // 2.5 seconds between redirects
        private const val COUNTER_RESET_MS = 30000L  // Reset counter after 30 seconds
        private const val OVERLAY_COOLDOWN_MS = 5000L  // 5 seconds after overlay dismissed
        private const val REDIRECT_DELAY_MS = 400L  // Delay before back action
        
        var isRunning = false
            private set
        var eventSink: EventChannel.EventSink? = null
        private var serviceInstance: ReelsMonitorService? = null

        fun updateSettings() {
            serviceInstance?.reloadSettings()
        }
    }

    private lateinit var usageRepository: UsageRepository
    private lateinit var powerManager: PowerManager
    private var windowManager: WindowManager? = null

    private var blockingOverlay: View? = null
    private var isOverlayShown = false

    // State
    private var currentPackage = ""
    private var isOnShortContent = false
    private var isScreenOn = true
    
    // Timing
    private var lastTrackTime = 0L
    private var lastRedirectTime = 0L
    private var lastOverlayDismissTime = 0L
    
    // Redirect counter
    private var redirectCount = 0
    private var lastCounterIncrementTime = 0L
    
    // Flags
    private var isActionInProgress = false

    private val handler = Handler(Looper.getMainLooper())

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                    stopTracking()
                    logDebug("Screen OFF")
                }
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOn = true
                    logDebug("Screen ON")
                }
            }
        }
    }

    /**
     * MAIN LOOP - Runs every second
     */
    private val mainLoop = object : Runnable {
        override fun run() {
            if (isScreenOn && !isActionInProgress) {
                checkAndProcess()
            }
            handler.postDelayed(this, CHECK_INTERVAL_MS)
        }
    }

    /**
     * Check current state and process
     */
    private fun checkAndProcess() {
        // Only process if we're in a monitored app
        val blockedApps = usageRepository.getBlockedApps()
        if (currentPackage !in blockedApps) {
            if (isOnShortContent) {
                logDebug("Left monitored app")
                isOnShortContent = false
                lastTrackTime = 0L
            }
            return
        }
        
        // Check if on shorts
        val onShorts = detectShorts()
        
        // State changed
        if (onShorts != isOnShortContent) {
            isOnShortContent = onShorts
            if (onShorts) {
                logDebug(">>> SHORTS DETECTED in $currentPackage")
            } else {
                logDebug("<<< Left shorts, now on feed")
                lastTrackTime = 0L
                if (isOverlayShown) forceHideOverlay()
            }
        }
        
        // Process
        if (isOnShortContent) {
            val limitReached = usageRepository.isLimitReached()
            val isPaused = usageRepository.isPaused()
            
            logDebug("On shorts | Limit: $limitReached | Paused: $isPaused | Used: ${usageRepository.getTodayUsageMinutes()} min")
            
            if (limitReached && !isPaused) {
                handleBlocking()
            } else {
                trackTime()
            }
        }
    }

    /**
     * Detect if currently on shorts
     */
    private fun detectShorts(): Boolean {
        val root = try {
            rootInActiveWindow
        } catch (e: Exception) {
            null
        }
        
        if (root == null) {
            logDebug("Root window is null")
            return false
        }
        
        val isShorts = when (currentPackage) {
            "com.instagram.android" -> detectInstagramReels(root)
            "com.google.android.youtube" -> detectYouTubeShorts(root)
            "com.facebook.katana" -> detectFacebookReels(root)
            "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> true
            else -> false
        }
        
        try { root.recycle() } catch (e: Exception) {}
        
        return isShorts
    }

    private fun detectInstagramReels(root: AccessibilityNodeInfo): Boolean {
        val ids = listOf(
            "com.instagram.android:id/clips_viewer_view_pager",
            "com.instagram.android:id/clips_video_container",
            "com.instagram.android:id/reel_viewer_root"
        )
        return findAnyId(root, ids)
    }

    private fun detectYouTubeShorts(root: AccessibilityNodeInfo): Boolean {
        val ids = listOf(
            "com.google.android.youtube:id/reel_recycler_view",
            "com.google.android.youtube:id/shorts_player_container",
            "com.google.android.youtube:id/reel_player_page_container"
        )
        return findAnyId(root, ids)
    }

    private fun detectFacebookReels(root: AccessibilityNodeInfo): Boolean {
        val ids = listOf(
            "com.facebook.katana:id/reels_viewer_container"
        )
        return findAnyId(root, ids)
    }

    private fun findAnyId(root: AccessibilityNodeInfo, ids: List<String>): Boolean {
        for (id in ids) {
            try {
                val nodes = root.findAccessibilityNodeInfosByViewId(id)
                if (nodes != null && nodes.isNotEmpty()) {
                    nodes.forEach { try { it.recycle() } catch (e: Exception) {} }
                    logDebug("Found ID: $id")
                    return true
                }
            } catch (e: Exception) {}
        }
        return false
    }

    /**
     * Track time spent on shorts
     */
    private fun trackTime() {
        val now = System.currentTimeMillis()
        if (lastTrackTime > 0) {
            val elapsed = now - lastTrackTime
            if (elapsed in 500..2000) {
                usageRepository.addUsage(elapsed, currentPackage)
                sendUsageUpdate()
                logDebug("Tracked ${elapsed}ms, Total: ${usageRepository.getTodayUsageMinutes()} min")
            }
        }
        lastTrackTime = now
    }

    /**
     * Handle blocking when limit is reached
     */
    private fun handleBlocking() {
        val now = System.currentTimeMillis()
        
        // Check cooldown
        if (now - lastRedirectTime < REDIRECT_COOLDOWN_MS) {
            logDebug("In redirect cooldown, waiting...")
            return
        }
        
        // Reset counter if enough time passed without attempts
        if (now - lastCounterIncrementTime > COUNTER_RESET_MS) {
            redirectCount = 0
            logDebug("Counter reset due to timeout")
        }
        
        // Increment counter
        redirectCount++
        lastCounterIncrementTime = now
        lastRedirectTime = now
        
        logDebug("=== BLOCKING ATTEMPT #$redirectCount ===")
        
        if (redirectCount <= MAX_SILENT_REDIRECTS) {
            logDebug("Silent redirect #$redirectCount")
            performSilentRedirect()
        } else {
            // Show overlay if not in cooldown
            if (now - lastOverlayDismissTime > OVERLAY_COOLDOWN_MS) {
                logDebug("Showing overlay after $redirectCount attempts")
                showBlockingOverlay()
            } else {
                logDebug("Overlay in cooldown, doing silent redirect")
                performSilentRedirect()
            }
        }
    }

    /**
     * Silently redirect to feed
     */
    private fun performSilentRedirect() {
        if (isActionInProgress) {
            logDebug("Action already in progress")
            return
        }
        
        isActionInProgress = true
        isOnShortContent = false
        lastTrackTime = 0L
        
        handler.postDelayed({
            logDebug("Executing BACK action")
            performGlobalAction(GLOBAL_ACTION_BACK)
            
            handler.postDelayed({
                isActionInProgress = false
                logDebug("Action complete")
            }, 800)
        }, REDIRECT_DELAY_MS)
    }

    private fun stopTracking() {
        isOnShortContent = false
        lastTrackTime = 0L
        isActionInProgress = false
        forceHideOverlay()
    }

    // ================== LIFECYCLE ==================

    override fun onCreate() {
        super.onCreate()
        serviceInstance = this
        isRunning = true
        usageRepository = UsageRepository.getInstance(this)
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        isScreenOn = powerManager.isInteractive

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(screenReceiver, filter)

        handler.post(mainLoop)

        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
        
        logDebug("========================================")
        logDebug("Service Started")
        logDebug("Daily Limit: ${usageRepository.getDailyLimit()} min")
        logDebug("Today's Usage: ${usageRepository.getTodayUsageMinutes()} min")
        logDebug("Limit Reached: ${usageRepository.isLimitReached()}")
        logDebug("========================================")
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceInstance = null
        isRunning = false
        handler.removeCallbacksAndMessages(null)
        forceHideOverlay()
        try { unregisterReceiver(screenReceiver) } catch (e: Exception) {}
        logDebug("Service Destroyed")
    }

    override fun onInterrupt() {
        handler.removeCallbacksAndMessages(null)
        forceHideOverlay()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = serviceInfo
        info.flags = info.flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
        serviceInfo = info
        logDebug("Service Connected - Key events enabled")
    }

    /**
     * IMPORTANT: Track which app is currently active
     */
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        
        val packageName = event.packageName?.toString() ?: return
        
        // Track current package
        if (packageName != currentPackage) {
            currentPackage = packageName
            logDebug("App changed: $packageName")
            
            // Reset state when leaving monitored apps
            val blockedApps = usageRepository.getBlockedApps()
            if (packageName !in blockedApps) {
                isOnShortContent = false
                lastTrackTime = 0L
                if (isOverlayShown) forceHideOverlay()
            }
        }
    }

    override fun onKeyEvent(event: KeyEvent?): Boolean {
        if (event == null) return super.onKeyEvent(event)
        
        if (isOverlayShown && event.keyCode == KeyEvent.KEYCODE_BACK) {
            if (event.action == KeyEvent.ACTION_UP) {
                logDebug("Back key pressed on overlay")
                dismissOverlay(goBack = true)
            }
            return true
        }
        
        return super.onKeyEvent(event)
    }

    fun reloadSettings() {
        logDebug("Settings reloaded")
        if (usageRepository.isPaused()) forceHideOverlay()
    }

    // ================== OVERLAY ==================

    private lateinit var vibrator: android.os.Vibrator //Vibrator 

    private fun showBlockingOverlay() {
        if (isOverlayShown || isActionInProgress) return
        
        isActionInProgress = true
        isOnShortContent = false
        lastTrackTime = 0L

        handler.post {
            try {
                val inflater = LayoutInflater.from(this)
                val overlay = inflater.inflate(R.layout.blocking_overlay, null)

                overlay.findViewById<TextView>(R.id.tvUsedTime)?.text =
                    "${usageRepository.getTodayUsageMinutes()} min"
                overlay.findViewById<TextView>(R.id.tvLimitTime)?.text =
                    "${usageRepository.getDailyLimit()} min"

                // Go Back button
                overlay.findViewById<Button>(R.id.btnGoBack)?.setOnTouchListener { v, event ->
                    if (event.action == MotionEvent.ACTION_UP) {
                        v.performClick()
                        dismissOverlay(goBack = true)
                    }
                    true
                }
                
                // Open App button
                overlay.findViewById<Button>(R.id.btnOpenApp)?.setOnTouchListener { v, event ->
                    if (event.action == MotionEvent.ACTION_UP) {
                        v.performClick()
                        dismissOverlay(openApp = true)
                    }
                    true
                }

                // Background tap
                overlay.setOnTouchListener { _, event ->
                    if (event.action == MotionEvent.ACTION_UP) {
                        dismissOverlay(goHome = true)
                    }
                    true
                }

                // Add Haptic Feedback
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    vibrator.vibrate(android.os.VibrationEffect.createOneShot(50, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    vibrator.vibrate(50)
                }
                
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                )
                params.gravity = Gravity.CENTER

                windowManager?.addView(overlay, params)
                blockingOverlay = overlay
                isOverlayShown = true
                isActionInProgress = false

                logDebug("Overlay SHOWN")

            } catch (e: Exception) {
                logDebug("Error showing overlay: ${e.message}")
                isOverlayShown = false
                isActionInProgress = false
            }
        }
    }

    private fun dismissOverlay(goBack: Boolean = false, goHome: Boolean = false, openApp: Boolean = false) {
        logDebug("Dismissing overlay - back:$goBack home:$goHome app:$openApp")
        
        lastOverlayDismissTime = System.currentTimeMillis()
        lastRedirectTime = System.currentTimeMillis()
        redirectCount = 0
        isActionInProgress = true
        
        forceHideOverlay()
        
        handler.postDelayed({
            when {
                goBack -> {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    logDebug("Back action after overlay")
                }
                goHome -> {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    logDebug("Home action after overlay")
                }
                openApp -> {
                    try {
                        val intent = packageManager.getLaunchIntentForPackage(packageName)
                        intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        if (intent != null) startActivity(intent)
                        logDebug("Opened Unscroll app")
                    } catch (e: Exception) {
                        logDebug("Error opening app: ${e.message}")
                    }
                }
            }
            
            handler.postDelayed({
                isActionInProgress = false
            }, 500)
        }, 200)
    }

    private fun forceHideOverlay() {
        val overlay = blockingOverlay
        blockingOverlay = null
        isOverlayShown = false
        
        if (overlay != null) {
            try {
                windowManager?.removeView(overlay)
                logDebug("Overlay HIDDEN")
            } catch (e: Exception) {}
        }
    }

    // ================== EVENTS ==================

    private fun sendUsageUpdate() {
        try {
            val data = hashMapOf(
                "type" to "usage_update",
                "totalMinutes" to usageRepository.getTodayUsageMinutes(),
                "limitMinutes" to usageRepository.getDailyLimit(),
                "remainingMinutes" to usageRepository.getRemainingMinutes(),
                "isLimitReached" to usageRepository.isLimitReached()
            )
            handler.post { eventSink?.success(data) }
        } catch (e: Exception) {}
    }
    
    private fun logDebug(msg: String) { 
        if (DEBUG) Log.d(TAG, msg) 
    }
}