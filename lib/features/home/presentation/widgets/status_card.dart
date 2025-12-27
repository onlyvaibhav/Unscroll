import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/platform_service.dart'; // Import PlatformService

class StatusCard extends StatelessWidget {
  final bool isAccessibilityEnabled;
  final bool hasOverlayPermission;
  final bool isServiceRunning;
  final bool isBatteryOptimizationDisabled; // 👈 New parameter
  final VoidCallback onEnableAccessibility;
  final VoidCallback onEnableOverlay;

  const StatusCard({
    super.key,
    required this.isAccessibilityEnabled,
    required this.hasOverlayPermission,
    required this.isServiceRunning,
    required this.isBatteryOptimizationDisabled, // 👈 New parameter
    required this.onEnableAccessibility,
    required this.onEnableOverlay,
  });

  bool get isFullyEnabled =>
      isAccessibilityEnabled && hasOverlayPermission && isServiceRunning;

  @override
  Widget build(BuildContext context) {
    if (isFullyEnabled && isBatteryOptimizationDisabled) { // Check battery too
      return _buildSuccessCard(context);
    }
    return _buildSetupCard(context);
  }

  Widget _buildSuccessCard(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppTheme.successGreen.withValues(alpha: 0.15),
          AppTheme.successGreen.withValues(alpha: 0.05),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppTheme.successGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protection Active',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All permissions granted • Service running',
                  style: TextStyle(
                    color: AppTheme.successGreen.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSetupCard(BuildContext context) {
    final int completedSteps = [
      isAccessibilityEnabled,
      hasOverlayPermission,
      isServiceRunning,
      isBatteryOptimizationDisabled, // Include battery step
    ].where((e) => e).length;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setup Required',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedSteps of 4 steps completed', // Updated count
                      style: const TextStyle(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completedSteps / 4, // Updated count
              backgroundColor: AppTheme.darkSurfaceLight,
              valueColor: AlwaysStoppedAnimation(
                completedSteps == 4 ? AppTheme.successGreen : AppTheme.warningOrange,
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 20),

          // Permission Items
          _PermissionItem(
            icon: Icons.accessibility_new_rounded,
            title: 'Accessibility Service',
            subtitle: 'Required to detect Reels & Shorts',
            isEnabled: isAccessibilityEnabled,
            onEnable: onEnableAccessibility,
          ),

          const SizedBox(height: 12),

          _PermissionItem(
            icon: Icons.layers_rounded,
            title: 'Overlay Permission',
            subtitle: 'Required to show blocking screen',
            isEnabled: hasOverlayPermission,
            onEnable: onEnableOverlay,
          ),

          const SizedBox(height: 12),

          // Battery Optimization Item 👈 NEW
          if (!isBatteryOptimizationDisabled) ...[
            _PermissionItem(
              icon: Icons.battery_alert_rounded,
              title: 'Ignore Battery Optimization',
              subtitle: 'Prevents service from stopping',
              isEnabled: false,
              onEnable: () {
                PlatformService.instance.requestIgnoreBatteryOptimizations();
              },
            ),
            const SizedBox(height: 12),
          ],

          _PermissionItem(
            icon: Icons.miscellaneous_services_rounded,
            title: 'Service Status',
            subtitle: isServiceRunning 
                ? 'Service is running' 
                : 'Enable accessibility to start',
            isEnabled: isServiceRunning,
            isServiceStatus: true,
          ),

          // Help Text
          if (!isAccessibilityEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.accentCyan,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Find "Unscroll" in accessibility settings and enable it',
                      style: TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final VoidCallback? onEnable;
  final bool isServiceStatus;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    this.onEnable,
    this.isServiceStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEnabled 
            ? AppTheme.successGreen.withValues(alpha: 0.1)
            : AppTheme.darkSurfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled 
              ? AppTheme.successGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled 
                  ? AppTheme.successGreen.withValues(alpha: 0.2)
                  : AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isEnabled ? AppTheme.successGreen : AppTheme.darkTextMuted,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isEnabled ? AppTheme.successGreen : AppTheme.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isEnabled 
                        ? AppTheme.successGreen.withValues(alpha: 0.8)
                        : AppTheme.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Action
          if (isEnabled)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.successGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            )
          else if (!isServiceStatus && onEnable != null)
            Material(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onEnable,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    'Enable',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppTheme.darkTextMuted,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}