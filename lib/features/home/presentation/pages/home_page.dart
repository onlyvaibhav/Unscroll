import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/home_bloc.dart';
import '../widgets/status_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/time_limit_card.dart';
import '../widgets/app_selector_card.dart';
import '../widgets/weekly_chart_card.dart';
import '../widgets/quick_actions.dart';
import '../../../settings/presentation/widgets/settings_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/serious_confirm_dialog.dart';
import '../../../../core/services/platform_service.dart';
import '../../../../core/services/password_service.dart';
import '../../../../core/widgets/pin_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const String _logoAsset = 'assets/icons/unscroll.png';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeBloc>().add(RefreshPermissions());
      context.read<HomeBloc>().add(RefreshHomeData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BlocConsumer<HomeBloc, HomeState>(
            listener: (context, state) {
              if (state.status == HomeStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppTheme.dangerRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state.status == HomeStatus.initial) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryPurple,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  context.read<HomeBloc>().add(LoadHomeData());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryPurple,
                backgroundColor: AppTheme.darkSurface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _buildAppBar(context, state),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (state.isPaused) _buildPauseBanner(context, state),

                          StatusCard(
                            isAccessibilityEnabled: state.isAccessibilityEnabled,
                            hasOverlayPermission: state.hasOverlayPermission,
                            isServiceRunning: state.isServiceRunning,
                            isBatteryOptimizationDisabled: state.isBatteryOptimizationDisabled,
                            onEnableAccessibility: () {
                              HapticFeedback.mediumImpact();
                              PlatformService.instance.openAccessibilitySettings();
                            },
                            onEnableOverlay: () {
                              HapticFeedback.mediumImpact();
                              PlatformService.instance.requestOverlayPermission();
                            },
                          ),

                          const SizedBox(height: 16),

                          StatsCard(
                            usedMinutes: state.todayUsageMinutes,
                            limitMinutes: state.dailyLimitMinutes,
                            remainingMinutes: state.remainingMinutes,
                            usagePercentage: state.usagePercentage,
                            onReset: state.isStrictMode
                                ? null
                                : () => _showResetConfirmation(context),
                          ),

                          const SizedBox(height: 16),

                          QuickActionsCard(
                          isPaused: state.isPaused,
                          onRefresh: () {
                            context.read<HomeBloc>().add(LoadHomeData());
                          },
                          onPauseResume: () async { // 👈 Make async
                            if (state.isPaused) {
                              context.read<HomeBloc>().add(ResumeBlocking());
                            } else {
                              // === COPY THE EXACT SAME LOGIC AS ABOVE ===
                              final passwordService = PasswordService.instance;
                              final isLimitReached = state.usagePercentage >= 1.0;

                              if (state.isStrictMode && isLimitReached) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot pause: Strict Mode active & Limit reached'),
                                    backgroundColor: AppTheme.dangerRed,
                                  ),
                                );
                                return;
                              }

                              if (isLimitReached) {
                                final confirmed = await showSeriousConfirmation(
                                  context,
                                  title: 'Pause Protection?',
                                  message: 'Limit reached. Pausing defeats the purpose.',
                                  type: ConfirmationType.critical,
                                );
                                if (!confirmed) return;
                              }

                              if ((state.isStrictMode || isLimitReached) && passwordService.isPasswordEnabled()) {
                                final verified = await showPinVerificationDialog(
                                  context,
                                  title: 'Verify Identity',
                                  subtitle: 'Enter PIN to pause',
                                  onVerify: (pin) async => passwordService.verifyPassword(pin),
                                );
                                if (!verified) return;
                              }

                              if (context.mounted) {
                                _showPauseDialog(context);
                              }
                            }
                          },
                          onShare: () => _shareApp(context),
                          onFocusMode: () => _showFocusModeSheet(context),
                        ),

                          const SizedBox(height: 16),

                          // Inside the SliverList delegate...

                        TimeLimitCard(
                          currentLimit: state.dailyLimitMinutes,
                          
                          // 🔒 LOCK LOGIC: 
                          // If Strict Mode is ON AND Limit is Reached -> Lock Slider completely
                          isLocked: state.isStrictMode && state.todayUsageMinutes >= state.dailyLimitMinutes,
                          
                          onLimitChanged: (minutes) async {
                            // If trying to INCREASE limit while Limit Reached (even if not Strict Mode)
                            if (state.todayUsageMinutes >= state.dailyLimitMinutes && 
                                minutes > state.dailyLimitMinutes) {
                                
                              final passwordService = PasswordService.instance;
                              
                              // Show Warning
                              final confirmed = await showSeriousConfirmation(
                                context,
                                title: 'Increase Limit?',
                                message: 'You have already reached your limit for today.',
                                additionalInfo: 'Extending time defeats the purpose of focusing.',
                                confirmText: 'Increase Anyway',
                                cancelText: 'Keep Limit',
                                type: ConfirmationType.critical,
                                icon: Icons.timer_off_rounded,
                              );
                              
                              if (!confirmed) {
                                // Reset UI to old value by forcing a rebuild (simple way is just return)
                                setState(() {}); 
                                return;
                              }

                              // Require PIN if enabled
                              if (passwordService.isPasswordEnabled()) {
                                final verified = await showPinVerificationDialog(
                                  context,
                                  title: 'Verify Identity',
                                  subtitle: 'Enter PIN to increase limit',
                                  onVerify: (pin) async => passwordService.verifyPassword(pin),
                                );
                                
                                if (!verified) {
                                  setState(() {}); // Reset UI
                                  return;
                                }
                              }
                            }
                            
                            // If all checks pass, update limit
                            if (context.mounted) {
                              context.read<HomeBloc>().add(UpdateDailyLimit(minutes));
                            }
                          },
                        ),

                          const SizedBox(height: 16),

                          AppSelectorCard(
                          blockedApps: state.blockedApps,
                          usageByApp: state.usageByApp,
                          
                          // 🔒 HARD LOCK: Strict Mode + Limit Reached
                          isLocked: state.isStrictMode && state.todayUsageMinutes >= state.dailyLimitMinutes,
                          
                          onToggle: (packageName, enabled) async {
                            // If we are UNBLOCKING (relaxing rules)
                            if (!enabled) { 
                              final passwordService = PasswordService.instance;
                              final isLimitReached = state.todayUsageMinutes >= state.dailyLimitMinutes;

                              // 1. Limit Reached Check (even if not Strict Mode)
                              if (isLimitReached) {
                                final confirmed = await showSeriousConfirmation(
                                  context,
                                  title: 'Unblock App?',
                                  message: 'You have reached your daily limit.',
                                  additionalInfo: 'Unblocking now defeats the purpose.',
                                  confirmText: 'Unblock Anyway',
                                  type: ConfirmationType.critical,
                                  icon: Icons.lock_open_rounded,
                                );
                                if (!confirmed) return;
                              }

                              // 2. PIN Check (Strict Mode OR Limit Reached)
                              if ((state.isStrictMode || isLimitReached) &&
                                  passwordService.isPasswordEnabled()) {
                                final verified = await showPinVerificationDialog(
                                  context,
                                  title: 'Verify Identity',
                                  subtitle: 'Enter PIN to unblock app',
                                  onVerify: (pin) async => passwordService.verifyPassword(pin),
                                );
                                if (!verified) return;
                              }
                            }

                            // Perform the toggle if checks pass (or if blocking, which is allowed)
                            if (context.mounted) {
                              context.read<HomeBloc>().add(
                                    ToggleBlockedApp(packageName, enabled),
                                  );
                            }
                          },
                        ),

                          const SizedBox(height: 16),

                          WeeklyChartCard(
                            weeklyUsage: state.weeklyUsage,
                            dailyLimit: state.dailyLimitMinutes,
                          ),

                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, HomeState state) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.primaryGlow,
            ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
            _logoAsset,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            ),
          ),
            ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'Unscroll',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                state.isFullyEnabled ? 'Protection active' : 'Setup required',
                style: TextStyle(
                  fontSize: 12,
                  color: state.isFullyEnabled 
                      ? AppTheme.successGreen 
                      : AppTheme.warningOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Pause/Resume Button
        if (state.isFullyEnabled)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: state.isPaused
                  ? AppTheme.warningOrange.withValues(alpha: 0.15)
                  : AppTheme.darkSurfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: state.isPaused ? AppTheme.warningOrange : AppTheme.darkText,
              ),
              tooltip: state.isPaused ? 'Resume blocking' : 'Pause blocking',
              onPressed: () async {
                HapticFeedback.mediumImpact();

                // If currently paused, just resume (no protection needed to resume)
                if (state.isPaused) {
                  context.read<HomeBloc>().add(ResumeBlocking());
                  return;
                }

                // === PAUSE LOGIC STARTS HERE ===
                final passwordService = PasswordService.instance;
                final isLimitReached = state.usagePercentage >= 1.0;

                // 1. Strict Mode + Limit Reached -> BLOCKED
                if (state.isStrictMode && isLimitReached) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Cannot pause: Strict Mode active & Limit reached'),
                        ],
                      ),
                      backgroundColor: AppTheme.dangerRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  return;
                }

                // 2. Limit Reached -> Serious Warning
                if (isLimitReached) {
                  final confirmed = await showSeriousConfirmation(
                    context,
                    title: 'Pause Protection?',
                    message: 'You have reached your daily limit.',
                    additionalInfo: 'Pausing now defeats the purpose of your goal.',
                    confirmText: 'Pause Anyway',
                    type: ConfirmationType.critical,
                    icon: Icons.timer_off_rounded,
                  );
                  if (!confirmed) return;
                }

                // 3. Strict Mode OR Limit Reached -> Require PIN
                if ((state.isStrictMode || isLimitReached) &&
                    passwordService.isPasswordEnabled()) {
                  final verified = await showPinVerificationDialog(
                    context,
                    title: 'Verify Identity',
                    subtitle: 'Enter PIN to pause protection',
                    onVerify: (pin) async => passwordService.verifyPassword(pin),
                  );
                  if (!verified) return;
                }

                // 4. If passed all checks, show pause dialog
                if (context.mounted) {
                  _showPauseDialog(context);
                }
              },
            ),
          ).animate().fadeIn(delay: 300.ms),

        // Settings Button
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildPauseBanner(BuildContext context, HomeState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningOrange.withOpacity(0.15),
            AppTheme.warningOrange.withOpacity(0.05),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pause_circle_filled_rounded,
                color: AppTheme.warningOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blocking Paused',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningOrange,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Tap to resume protection',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<HomeBloc>().add(ResumeBlocking());
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.warningOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Resume',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn()
      .slideY(begin: -0.5)
      .then()
      .shimmer(duration: 2.seconds, color: AppTheme.warningOrange.withOpacity(0.3));
  }

  void _showPauseDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsHandle(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    color: AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pause Blocking',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'How long do you need?',
                      style: TextStyle(color: AppTheme.darkTextSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [5, 10, 15, 30, 60].map((minutes) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.read<HomeBloc>().add(PauseBlocking(minutes));
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Text(
                        minutes >= 60 ? '${minutes ~/ 60}h' : '$minutes min',
                        style: const TextStyle(
                          color: AppTheme.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SETTINGS BOTTOM SHEET - FIXED WITH BLOCBUILDER
  // ============================================
  void _showSettingsBottomSheet(BuildContext context) {
    final passwordService = PasswordService.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocBuilder<HomeBloc, HomeState>(
        // 👈 USE BLOCBUILDER to get live state updates!
        builder: (context, state) {
          final isLimitReached = state.usagePercentage >= 1.0;

          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        children: [
                          const SettingsHandle(),
                          Row(
                            children: [
                              const SettingsHeader(
                                title: 'Settings',
                                icon: Icons.settings_rounded,
                              ),
                              const Spacer(),
                              // Limit reached badge
                              if (isLimitReached)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRed.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.dangerRed.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        color: AppTheme.dangerRed,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Locked',
                                        style: TextStyle(
                                          color: AppTheme.dangerRed,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().scale(),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ═══════════════════════════════════════
                            // SECURITY SECTION
                            // ═══════════════════════════════════════
                            const SettingsSectionHeader(title: '🔐 Security'),

                            // PIN Protection
                            SettingsTile(
                              icon: Icons.pin_rounded,
                              iconColor: AppTheme.primaryPurple,
                              title: 'PIN Protection',
                              subtitle: passwordService.isPasswordEnabled()
                                  ? 'Enabled • Protects settings'
                                  : 'Protect with a 4-digit PIN',
                              switchValue: passwordService.isPasswordEnabled(),
                              onSwitchChanged: (value) async {
                                if (value) {
                                  // Enabling PIN
                                  final success = await showPinSetupDialog(
                                    context,
                                    onSetup: (pin) async {
                                      return await passwordService.setPassword(pin);
                                    },
                                  );
                                  if (success) {
                                    setSheetState(() {});
                                    _showSuccessSnackbar(context, 'PIN enabled');
                                  }
                                } else {
                                  // Disabling PIN - need extra checks
                                  if (isLimitReached) {
                                    final confirmed = await showLimitReachedWarning(
                                      context,
                                      action: 'Disable PIN protection',
                                    );
                                    if (!confirmed) return;
                                  }

                                  final verified = await showPinVerificationDialog(
                                    context,
                                    title: 'Disable PIN',
                                    subtitle: 'Enter current PIN to disable',
                                    onVerify: (pin) async {
                                      return passwordService.verifyPassword(pin);
                                    },
                                  );
                                  if (verified) {
                                    await passwordService.removePassword();
                                    setSheetState(() {});
                                    _showSuccessSnackbar(context, 'PIN disabled');
                                  }
                                }
                              },
                            ),

                            // Change PIN
                            if (passwordService.isPasswordEnabled()) ...[
                              const SizedBox(height: 12),
                              SettingsTile(
                                icon: Icons.lock_reset_rounded,
                                iconColor: AppTheme.accentCyan,
                                title: 'Change PIN',
                                subtitle: 'Update your security PIN',
                                onTap: () => _handleChangePin(context, passwordService),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ═══════════════════════════════════════
                            // BLOCKING SECTION
                            // ═══════════════════════════════════════
                            const SettingsSectionHeader(title: '🛡️ Blocking'),

                            // Strict Mode - FIXED!
                            _buildStrictModeTile(
                              context,
                              state,
                              isLimitReached,
                              passwordService,
                              setSheetState,
                            ),

                            const SizedBox(height: 24),

                            // ═══════════════════════════════════════
                            // DATA SECTION
                            // ═══════════════════════════════════════
                            const SettingsSectionHeader(title: '📊 Data'),

                            SettingsTile(
                              icon: Icons.refresh_rounded,
                              iconColor: AppTheme.accentCyan,
                              title: 'Reset Today\'s Usage',
                              subtitle: 'Set the counter back to 0 minutes',
                              onTap: () {
                                Navigator.pop(ctx);
                                _showResetConfirmation(context);
                              },
                            ),

                            const SizedBox(height: 12),

                            SettingsDangerTile(
                              icon: Icons.delete_forever_rounded,
                              title: 'Clear All Data',
                              subtitle: 'Permanently delete all usage history',
                              onTap: () {
                                Navigator.pop(ctx);
                                _showClearAllConfirmation(context);
                              },
                            ),

                            const SizedBox(height: 24),

                            // ═══════════════════════════════════════
                            // ABOUT SECTION
                            // ═══════════════════════════════════════
                            const SettingsSectionHeader(title: 'ℹ️ About'),

                            SettingsTile(
                              icon: Icons.info_outline_rounded,
                              iconColor: AppTheme.primaryPurple,
                              title: 'About Unscroll',
                              subtitle: 'Version 1.0.1 • Made with ❤️',
                              onTap: () {
                                Navigator.pop(ctx);
                                _showAboutDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================
  // STRICT MODE TILE - COMPLETELY FIXED
  // ============================================
  Widget _buildStrictModeTile(
    BuildContext context,
    HomeState state,
    bool isLimitReached,
    PasswordService passwordService,
    StateSetter setSheetState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isStrictMode
              ? AppTheme.warningOrange.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: AppTheme.warningOrange,
                  size: 22,
                ),
                if (isLimitReached)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.darkSurfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppTheme.dangerRed,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Strict Mode',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.isStrictMode
                      ? 'On • Cannot bypass limits'
                      : 'Prevent bypassing the limit',
                  style: const TextStyle(
                    color: AppTheme.darkTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Custom Switch
          _StrictModeSwitch(
            value: state.isStrictMode,
            onChanged: (newValue) async {
              HapticFeedback.selectionClick();

              // Check if PIN is required for strict mode
              if (!passwordService.isPasswordEnabled()) {
                // Must enable PIN first
                final enablePin = await showSeriousConfirmation(
                  context,
                  title: 'PIN Required',
                  message: 'Strict Mode requires PIN protection to be enabled first. This ensures you can\'t easily bypass the blocker.',
                  confirmText: 'Set Up PIN',
                  cancelText: 'Not Now',
                  type: ConfirmationType.warning,
                  icon: Icons.pin_rounded,
                );

                if (!enablePin || !context.mounted) return;

                // Setup PIN
                final pinSet = await showPinSetupDialog(
                  context,
                  onSetup: (pin) async {
                    return await passwordService.setPassword(pin);
                  },
                );

                if (!pinSet) {
                  _showErrorSnackbar(context, 'PIN is required for Strict Mode');
                  return;
                }

                setSheetState(() {});
              }

              // If limit reached, show serious warning
              if (isLimitReached) {
                final confirmed = await showLimitReachedWarning(
                  context,
                  action: newValue ? 'Enable Strict Mode' : 'Disable Strict Mode',
                );
                if (!confirmed) return;
              }

              // Show strict mode specific warning
              final confirmed = await showStrictModeWarning(
                context,
                enabling: newValue,
              );
              if (!confirmed) return;

              // Require PIN verification
              if (passwordService.isPasswordEnabled()) {
                final verified = await showPinVerificationDialog(
                  context,
                  title: 'Verify Identity',
                  subtitle: 'Enter PIN to ${newValue ? 'enable' : 'disable'} strict mode',
                  onVerify: (pin) async => passwordService.verifyPassword(pin),
                );
                if (!verified) return;
              }

              // Finally toggle strict mode
              if (context.mounted) {
                context.read<HomeBloc>().add(ToggleStrictMode(newValue));
                _showSuccessSnackbar(
                  context,
                  newValue ? 'Strict Mode enabled' : 'Strict Mode disabled',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleChangePin(BuildContext context, PasswordService passwordService) async {
    final verified = await showPinVerificationDialog(
      context,
      title: 'Current PIN',
      subtitle: 'Enter your current PIN',
      onVerify: (pin) async {
        return passwordService.verifyPassword(pin);
      },
    );

    if (!verified || !context.mounted) return;

    final success = await showPinSetupDialog(
      context,
      onSetup: (pin) async {
        return await passwordService.setPassword(pin);
      },
    );

    if (success && context.mounted) {
      _showSuccessSnackbar(context, 'PIN changed successfully');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final passwordService = PasswordService.instance;
    final state = context.read<HomeBloc>().state;
    final isLimitReached = state.usagePercentage >= 1.0;

    // If limit reached, show serious warning first
    if (isLimitReached) {
      final confirmed = await showLimitReachedWarning(
        context,
        action: 'Reset today\'s usage',
      );
      if (!confirmed) return;
    }

    // Require PIN if enabled
    if (passwordService.isPasswordEnabled()) {
      final verified = await showPinVerificationDialog(
        context,
        title: 'Enter PIN',
        subtitle: 'Enter your PIN to reset usage',
        onVerify: (pin) async {
          return passwordService.verifyPassword(pin);
        },
      );
      if (!verified) return;
    }

    if (!context.mounted) return;

    // Final confirmation
    final confirmed = await showSeriousConfirmation(
      context,
      title: 'Reset Usage?',
      message: 'This will reset your usage counter to 0 for today.',
      confirmText: 'Reset',
      type: ConfirmationType.warning,
      icon: Icons.refresh_rounded,
    );

    if (confirmed && context.mounted) {
      context.read<HomeBloc>().add(ResetTodayUsage());
      _showSuccessSnackbar(context, 'Usage reset successfully');
    }
  }

  void _showClearAllConfirmation(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final passwordService = PasswordService.instance;
    final state = context.read<HomeBloc>().state;
    final isLimitReached = state.usagePercentage >= 1.0;

    // If limit reached, show serious warning first
    if (isLimitReached) {
      final confirmed = await showLimitReachedWarning(
        context,
        action: 'Clear all data',
      );
      if (!confirmed) return;
    }

    // Require PIN if enabled
    if (passwordService.isPasswordEnabled()) {
      final verified = await showPinVerificationDialog(
        context,
        title: 'Enter PIN',
        subtitle: 'Enter your PIN to clear all data',
        onVerify: (pin) async {
          return passwordService.verifyPassword(pin);
        },
      );
      if (!verified) return;
    }

    if (!context.mounted) return;

    // Final confirmation with danger styling
    final confirmed = await showSeriousConfirmation(
      context,
      title: 'Clear All Data?',
      message: 'This will permanently delete ALL usage data including weekly history.',
      additionalInfo: 'This action cannot be undone!',
      confirmText: 'Delete All',
      type: ConfirmationType.danger,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed && context.mounted) {
      await PlatformService.instance.clearAllData();
      context.read<HomeBloc>().add(LoadHomeData());
      _showSuccessSnackbar(context, 'All data cleared');
    }
  }

  void _showFocusModeSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SettingsHandle(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Focus Mode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming in the next update! 🚀',
              style: TextStyle(color: AppTheme.darkTextSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pomodoro timer with complete app blocking',
              style: TextStyle(
                color: AppTheme.darkTextMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _shareApp(BuildContext context) {
    HapticFeedback.lightImpact();
    _showSuccessSnackbar(context, 'Share feature coming soon!');
  }

    void _showAboutDialog(BuildContext context) {
  const String appVersion = '1.0.1';
  const String devName = 'Vaibhav';
  const String githubUrl = 'https://github.com/onlyvaibhav/Unscroll';
  const String contactEmail = 'vaibhavmishra0707@gmail.com';

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),

          // 1. APP ICON
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icons/unscroll.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.darkSurfaceLight,
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App Name
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: const Text(
              'Unscroll',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Version Badge (non-const because of interpolation)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              'v$appVersion • Beta',
              style: TextStyle(
                color: AppTheme.primaryPurple,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Description
          const Text(
            'Take control of your screen time.\nBlock Reels & Shorts locally.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.darkTextSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // 2. GITHUB CARD
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                final Uri url = Uri.parse(githubUrl);
                try {
                  // open externally (browser / GitHub app)
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  debugPrint('Error launching GitHub URL: $e');
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.code_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Built by $devName',
                          style: TextStyle(
                            color: AppTheme.darkText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Open Source on GitHub',
                          style: TextStyle(
                            color: AppTheme.darkTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: AppTheme.darkTextMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. ACTION ROW (Licenses & Contact) — UPDATED LOGIC
          Row(
            children: [
              Expanded(
                child: _AboutActionButton(
                  icon: Icons.policy_rounded,
                  label: 'Licenses',
                  onTap: () {
                    // 1. Close dialog first
                    Navigator.of(ctx).pop();

                    // 2. Use parent context for license page
                    showLicensePage(
                      context: context,
                      applicationName: 'Unscroll',
                      applicationVersion: appVersion,
                      applicationIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/icons/unscroll.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AboutActionButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Contact',
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: contactEmail,
                      query:
                          'subject=Unscroll Feedback&body=App Version: $appVersion',
                    );

                    try {
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No email app found'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error launching email: $e');
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. TECH BADGE (Flutter)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 16),
              const SizedBox(width: 8),
              Text(
                'Made with Flutter',
                style: TextStyle(
                  color: AppTheme.darkTextMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
// Small Helper Widget for the Action Row
class _AboutActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AboutActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppTheme.darkTextSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================
// STRICT MODE SWITCH WIDGET
// ============================================
class _StrictModeSwitch extends StatefulWidget {
  final bool value;
  final Future<void> Function(bool) onChanged;

  const _StrictModeSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_StrictModeSwitch> createState() => _StrictModeSwitchState();
}

class _StrictModeSwitchState extends State<_StrictModeSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;
  late Animation<Color?> colorAnimation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    colorAnimation = ColorTween(
      begin: AppTheme.darkSurface,
      end: AppTheme.warningOrange,
    ).animate(animation);

    if (widget.value) {
      controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_StrictModeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              setState(() => isLoading = true);
              await widget.onChanged(!widget.value);
              if (mounted) {
                setState(() => isLoading = false);
              }
            },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Container(
            width: 52,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: colorAnimation.value,
              border: Border.all(
                color: widget.value
                    ? AppTheme.warningOrange.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: widget.value
                  ? [
                      BoxShadow(
                        color: AppTheme.warningOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: widget.value ? 24 : 3,
                  top: 3,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.warningOrange,
                            ),
                          )
                        : widget.value
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: AppTheme.warningOrange,
                              )
                            : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}