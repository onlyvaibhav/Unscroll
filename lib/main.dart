import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // For kReleaseMode
import 'package:shared_preferences/shared_preferences.dart'; // For onboarding check
import 'app.dart';
import 'core/services/platform_service.dart';
import 'core/services/password_service.dart';

void main() async {
  // Ensure bindings are initialized before native calls
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════
  // 1. PERFORMANCE OPTIMIZATIONS
  // ═══════════════════════════════════════════════════════
  
  // Disable expensive debug print logs in production
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Increase image cache memory (helps with scrolling lag)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB

  // ═══════════════════════════════════════════════════════
  // 2. SYSTEM UI CONFIGURATION
  // ═══════════════════════════════════════════════════════

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set immersive dark theme for status/nav bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark, // iOS
      systemNavigationBarColor: Color(0xFF0A0A0F), // Matches AppTheme.darkBg
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // ═══════════════════════════════════════════════════════
  // 3. INITIALIZE SERVICES & DATA
  // ═══════════════════════════════════════════════════════
  
  // Initialize backend services in parallel for faster startup
  await Future.wait([
    PlatformService.instance.initialize(),
    PasswordService.instance.initialize(),
  ]);

  // Check if user has completed onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('is_onboarding_complete') ?? false;

  runApp(UnscrollApp(
    showOnboarding: !onboardingComplete,
  ));
}