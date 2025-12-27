import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
    // Add this method to the existing PlatformService class
  
  /// Clears all usage data - use for debugging/reset
  Future<void> clearAllData() async {
    await _methodChannel.invokeMethod('clearAllData');
  }
  
  static final PlatformService instance = PlatformService._();
  PlatformService._();

  static const _methodChannel = MethodChannel('com.unscroll.app/methods');
  static const _eventChannel = EventChannel('com.unscroll.app/events');

  Stream<Map<dynamic, dynamic>>? _eventStream;

  Stream<Map<dynamic, dynamic>> get eventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<dynamic, dynamic>.from(event));
    return _eventStream!;
  }

  Future<void> initialize() async {
    eventStream.listen((event) {
      debugPrint('📱 Event from native: $event');
    }, onError: (error) {
      debugPrint('❌ Event stream error: $error');
    });
  }
  // ==================== BATTERY OPTIMIZATION ====================

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _methodChannel.invokeMethod('isIgnoringBatteryOptimizations') ?? false;
    } catch (e) {
      return true; // Assume true if fails to avoid blocking user
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint("Error requesting battery exemption: $e");
    }
  }
  // ==================== PERMISSIONS ====================

  Future<bool> isAccessibilityEnabled() async {
    try {
      return await _methodChannel.invokeMethod('isAccessibilityEnabled') ?? false;
    } catch (e) {
      debugPrint('Error checking accessibility: $e');
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    await _methodChannel.invokeMethod('openAccessibilitySettings');
  }

  Future<bool> hasOverlayPermission() async {
    try {
      return await _methodChannel.invokeMethod('hasOverlayPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    await _methodChannel.invokeMethod('requestOverlayPermission');
  }

  // ==================== DAILY LIMIT ====================

  Future<void> setDailyLimit(int minutes) async {
    await _methodChannel.invokeMethod('setDailyLimit', {'minutes': minutes});
  }

  Future<int> getDailyLimit() async {
    try {
      return await _methodChannel.invokeMethod('getDailyLimit') ?? 30;
    } catch (e) {
      return 30;
    }
  }

  // ==================== USAGE DATA ====================

  Future<int> getTodayUsageMs() async {
    try {
      final result = await _methodChannel.invokeMethod('getTodayUsage');
      return (result as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTodayUsageMinutes() async {
    final ms = await getTodayUsageMs();
    return (ms / 60000).round();
  }

  Future<Map<String, int>> getWeeklyUsage() async {
    try {
      final result = await _methodChannel.invokeMethod('getWeeklyUsage');
      if (result == null) return {};
      return Map<String, int>.from(result);
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, int>> getUsageByApp() async {
    try {
      final result = await _methodChannel.invokeMethod('getUsageByApp');
      if (result == null) return {};
      return Map<String, int>.from(result);
    } catch (e) {
      return {};
    }
  }

  Future<void> resetTodayUsage() async {
    await _methodChannel.invokeMethod('resetTodayUsage');
  }

  // ==================== BLOCKED APPS ====================

  Future<void> setBlockedApps(List<String> apps) async {
    await _methodChannel.invokeMethod('setBlockedApps', {'apps': apps});
  }

  Future<List<String>> getBlockedApps() async {
    try {
      final result = await _methodChannel.invokeMethod('getBlockedApps');
      return List<String>.from(result ?? []);
    } catch (e) {
      return [];
    }
  }

  // ==================== SERVICE STATUS ====================

  Future<bool> isServiceRunning() async {
    try {
      return await _methodChannel.invokeMethod('isServiceRunning') ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== STRICT MODE ====================

  Future<void> setStrictMode(bool enabled) async {
    await _methodChannel.invokeMethod('setStrictMode', {'enabled': enabled});
  }

  Future<bool> isStrictMode() async {
    try {
      return await _methodChannel.invokeMethod('isStrictMode') ?? false;
    } catch (e) {
      return false;
    }
  }

  // ==================== PAUSE FEATURE ====================

  Future<void> pauseFor(int minutes) async {
    await _methodChannel.invokeMethod('pauseFor', {'minutes': minutes});
  }

  Future<bool> isPaused() async {
    try {
      return await _methodChannel.invokeMethod('isPaused') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearPause() async {
    await _methodChannel.invokeMethod('clearPause');
  }
}