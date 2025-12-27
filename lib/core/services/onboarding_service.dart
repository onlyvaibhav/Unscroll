import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state
class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';

  static OnboardingService? _instance;
  static OnboardingService get instance {
    _instance ??= OnboardingService._();
    return _instance!;
  }

  OnboardingService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if user has completed onboarding
  bool hasCompletedOnboarding() {
    return _prefs?.getBool(_onboardingKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await _prefs?.setBool(_onboardingKey, true);
  }

  /// Reset onboarding (for testing purposes)
  Future<void> resetOnboarding() async {
    await _prefs?.remove(_onboardingKey);
  }
}