class AppConstants {
  // App Info
  static const String appName = 'Unscroll';
  static const String appVersion = '1.0.0';
  
  // Defaults
  static const int defaultDailyLimitMinutes = 30;
  static const int minLimitMinutes = 5;
  static const int maxLimitMinutes = 180;
  
  // Package Names
  static const String instagramPackage = 'com.instagram.android';
  static const String youtubePackage = 'com.google.android.youtube';
  static const String tiktokPackage = 'com.zhiliaoapp.musically';
  static const String tiktokAltPackage = 'com.ss.android.ugc.trill';
  static const String facebookPackage = 'com.facebook.katana';
  
  // Channel Names
  static const String methodChannel = 'com.unscroll.app/methods';
  static const String eventChannel = 'com.unscroll.app/events';
  
  // Storage Keys
  static const String keyDailyLimit = 'daily_limit';
  static const String keyBlockedApps = 'blocked_apps';
  static const String keyStrictMode = 'strict_mode';
  static const String keyOnboardingComplete = 'onboarding_complete';
}