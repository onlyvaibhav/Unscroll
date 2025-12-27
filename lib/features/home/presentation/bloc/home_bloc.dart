import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/platform_service.dart';

// ==================== EVENTS ====================

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class RefreshHomeData extends HomeEvent {}

class UpdateDailyLimit extends HomeEvent {
  final int minutes;
  const UpdateDailyLimit(this.minutes);
  
  @override
  List<Object?> get props => [minutes];
}

class ToggleBlockedApp extends HomeEvent {
  final String packageName;
  final bool isEnabled;
  const ToggleBlockedApp(this.packageName, this.isEnabled);
  
  @override
  List<Object?> get props => [packageName, isEnabled];
}

class ResetTodayUsage extends HomeEvent {}

class RefreshPermissions extends HomeEvent {}

class PauseBlocking extends HomeEvent {
  final int minutes;
  const PauseBlocking(this.minutes);
  
  @override
  List<Object?> get props => [minutes];
}

class ResumeBlocking extends HomeEvent {}

class ToggleStrictMode extends HomeEvent {
  final bool isEnabled;
  const ToggleStrictMode(this.isEnabled);
  
  @override
  List<Object?> get props => [isEnabled];
}

// ==================== STATE ====================

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final bool isAccessibilityEnabled;
  final bool hasOverlayPermission;
  final bool isServiceRunning;
  final bool isBatteryOptimizationDisabled; // 👈 New field
  final int dailyLimitMinutes;
  final int todayUsageMinutes;
  final int remainingMinutes;
  final double usagePercentage;
  final Map<String, int> weeklyUsage;
  final Map<String, int> usageByApp;
  final List<String> blockedApps;
  final bool isStrictMode;
  final bool isPaused;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.isAccessibilityEnabled = false,
    this.hasOverlayPermission = false,
    this.isServiceRunning = false,
    this.isBatteryOptimizationDisabled = true, // Default true to hide warning if check fails
    this.dailyLimitMinutes = 30,
    this.todayUsageMinutes = 0,
    this.remainingMinutes = 30,
    this.usagePercentage = 0,
    this.weeklyUsage = const {},
    this.usageByApp = const {},
    this.blockedApps = const [],
    this.isStrictMode = false,
    this.isPaused = false,
    this.errorMessage,
  });

  bool get isFullyEnabled =>
      isAccessibilityEnabled && hasOverlayPermission && isServiceRunning;

  bool get isLimitReached => todayUsageMinutes >= dailyLimitMinutes;

  HomeState copyWith({
    HomeStatus? status,
    bool? isAccessibilityEnabled,
    bool? hasOverlayPermission,
    bool? isServiceRunning,
    bool? isBatteryOptimizationDisabled,
    int? dailyLimitMinutes,
    int? todayUsageMinutes,
    int? remainingMinutes,
    double? usagePercentage,
    Map<String, int>? weeklyUsage,
    Map<String, int>? usageByApp,
    List<String>? blockedApps,
    bool? isStrictMode,
    bool? isPaused,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      isAccessibilityEnabled: isAccessibilityEnabled ?? this.isAccessibilityEnabled,
      hasOverlayPermission: hasOverlayPermission ?? this.hasOverlayPermission,
      isServiceRunning: isServiceRunning ?? this.isServiceRunning,
      isBatteryOptimizationDisabled: isBatteryOptimizationDisabled ?? this.isBatteryOptimizationDisabled,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      todayUsageMinutes: todayUsageMinutes ?? this.todayUsageMinutes,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      usagePercentage: usagePercentage ?? this.usagePercentage,
      weeklyUsage: weeklyUsage ?? this.weeklyUsage,
      usageByApp: usageByApp ?? this.usageByApp,
      blockedApps: blockedApps ?? this.blockedApps,
      isStrictMode: isStrictMode ?? this.isStrictMode,
      isPaused: isPaused ?? this.isPaused,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isAccessibilityEnabled,
        hasOverlayPermission,
        isServiceRunning,
        isBatteryOptimizationDisabled,
        dailyLimitMinutes,
        todayUsageMinutes,
        remainingMinutes,
        usagePercentage,
        weeklyUsage,
        usageByApp,
        blockedApps,
        isStrictMode,
        isPaused,
        errorMessage,
      ];
}

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PlatformService platformService;
  StreamSubscription? _eventSubscription;
  Timer? _refreshTimer;

  HomeBloc({required this.platformService}) : super(const HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<UpdateDailyLimit>(_onUpdateDailyLimit);
    on<ToggleBlockedApp>(_onToggleBlockedApp);
    on<ResetTodayUsage>(_onResetTodayUsage);
    on<RefreshPermissions>(_onRefreshPermissions);
    on<PauseBlocking>(_onPauseBlocking);
    on<ResumeBlocking>(_onResumeBlocking);
    on<ToggleStrictMode>(_onToggleStrictMode);

    // Listen to real-time updates from native
    _eventSubscription = platformService.eventStream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'usage_update' || type == 'state_update') {
        add(RefreshHomeData());
      }
    });

    // Periodic refresh (60 seconds for performance)
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      add(RefreshHomeData());
    });
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final results = await Future.wait([
        platformService.isAccessibilityEnabled(),
        platformService.hasOverlayPermission(),
        platformService.isServiceRunning(),
        platformService.getDailyLimit(),
        platformService.getTodayUsageMinutes(),
        platformService.getWeeklyUsage(),
        platformService.getUsageByApp(),
        platformService.getBlockedApps(),
        platformService.isStrictMode(),
        platformService.isPaused(),
        platformService.isIgnoringBatteryOptimizations(), // 👈 Added this
      ]);

      final dailyLimit = results[3] as int;
      final todayUsage = results[4] as int;
      final remaining = (dailyLimit - todayUsage).clamp(0, dailyLimit);
      final percentage = dailyLimit > 0 ? todayUsage / dailyLimit : 0.0;

      emit(state.copyWith(
        status: HomeStatus.loaded,
        isAccessibilityEnabled: results[0] as bool,
        hasOverlayPermission: results[1] as bool,
        isServiceRunning: results[2] as bool,
        dailyLimitMinutes: dailyLimit,
        todayUsageMinutes: todayUsage,
        remainingMinutes: remaining,
        usagePercentage: percentage,
        weeklyUsage: results[5] as Map<String, int>,
        usageByApp: results[6] as Map<String, int>,
        blockedApps: results[7] as List<String>,
        isStrictMode: results[8] as bool,
        isPaused: results[9] as bool,
        isBatteryOptimizationDisabled: results[10] as bool, // 👈 Added this
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    // Silent refresh without loading state
    try {
      final results = await Future.wait([
        platformService.isAccessibilityEnabled(),
        platformService.hasOverlayPermission(),
        platformService.isServiceRunning(),
        platformService.getDailyLimit(),
        platformService.getTodayUsageMinutes(),
        platformService.getWeeklyUsage(),
        platformService.getUsageByApp(),
        platformService.getBlockedApps(),
        platformService.isPaused(),
        platformService.isIgnoringBatteryOptimizations(), // 👈 Added this
      ]);

      final dailyLimit = results[3] as int;
      final todayUsage = results[4] as int;
      final remaining = (dailyLimit - todayUsage).clamp(0, dailyLimit);
      final percentage = dailyLimit > 0 ? todayUsage / dailyLimit : 0.0;

      emit(state.copyWith(
        status: HomeStatus.loaded,
        isAccessibilityEnabled: results[0] as bool,
        hasOverlayPermission: results[1] as bool,
        isServiceRunning: results[2] as bool,
        dailyLimitMinutes: dailyLimit,
        todayUsageMinutes: todayUsage,
        remainingMinutes: remaining,
        usagePercentage: percentage,
        weeklyUsage: results[5] as Map<String, int>,
        usageByApp: results[6] as Map<String, int>,
        blockedApps: results[7] as List<String>,
        isPaused: results[8] as bool,
        isBatteryOptimizationDisabled: results[9] as bool, // 👈 Added this
      ));
    } catch (e) {
      // Silent fail on refresh
    }
  }

  Future<void> _onUpdateDailyLimit(
    UpdateDailyLimit event,
    Emitter<HomeState> emit,
  ) async {
    await platformService.setDailyLimit(event.minutes);
    
    final todayUsage = state.todayUsageMinutes;
    final remaining = (event.minutes - todayUsage).clamp(0, event.minutes);
    final percentage = event.minutes > 0 ? todayUsage / event.minutes : 0.0;
    
    emit(state.copyWith(
      dailyLimitMinutes: event.minutes,
      remainingMinutes: remaining,
      usagePercentage: percentage,
    ));
  }

  Future<void> _onToggleBlockedApp(
    ToggleBlockedApp event,
    Emitter<HomeState> emit,
  ) async {
    final apps = List<String>.from(state.blockedApps);
    
    if (event.isEnabled && !apps.contains(event.packageName)) {
      apps.add(event.packageName);
    } else if (!event.isEnabled) {
      apps.remove(event.packageName);
    }
    
    await platformService.setBlockedApps(apps);
    emit(state.copyWith(blockedApps: apps));
  }

  Future<void> _onResetTodayUsage(
    ResetTodayUsage event,
    Emitter<HomeState> emit,
  ) async {
    await platformService.resetTodayUsage();
    emit(state.copyWith(
      todayUsageMinutes: 0,
      remainingMinutes: state.dailyLimitMinutes,
      usagePercentage: 0,
    ));
  }

  Future<void> _onRefreshPermissions(
    RefreshPermissions event,
    Emitter<HomeState> emit,
  ) async {
    final isAccessibilityEnabled = await platformService.isAccessibilityEnabled();
    final hasOverlayPermission = await platformService.hasOverlayPermission();
    final isServiceRunning = await platformService.isServiceRunning();
    final isBatteryOptimized = await platformService.isIgnoringBatteryOptimizations();

    emit(state.copyWith(
      isAccessibilityEnabled: isAccessibilityEnabled,
      hasOverlayPermission: hasOverlayPermission,
      isServiceRunning: isServiceRunning,
      isBatteryOptimizationDisabled: isBatteryOptimized,
    ));
  }

  Future<void> _onPauseBlocking(
    PauseBlocking event,
    Emitter<HomeState> emit,
  ) async {
    await platformService.pauseFor(event.minutes);
    emit(state.copyWith(isPaused: true));
  }

  Future<void> _onResumeBlocking(
    ResumeBlocking event,
    Emitter<HomeState> emit,
  ) async {
    await platformService.clearPause();
    emit(state.copyWith(isPaused: false));
  }

  Future<void> _onToggleStrictMode(
    ToggleStrictMode event,
    Emitter<HomeState> emit,
  ) async {
    await platformService.setStrictMode(event.isEnabled);
    emit(state.copyWith(isStrictMode: event.isEnabled));
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}