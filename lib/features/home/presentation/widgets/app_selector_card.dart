import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class AppSelectorCard extends StatelessWidget {
  final List<String> blockedApps;
  final Map<String, int> usageByApp;
  final Function(String packageName, bool enabled) onToggle;
  final bool isLocked; // 👈 NEW: To physically lock the UI

  const AppSelectorCard({
    super.key,
    required this.blockedApps,
    required this.usageByApp,
    required this.onToggle,
    this.isLocked = false, // Default false
  });

  @override
  Widget build(BuildContext context) {
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
                  gradient: isLocked
                      ? null
                      : AppTheme.primaryGradient, // Remove gradient if locked
                  color: isLocked ? AppTheme.darkSurfaceLight : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : Icons.apps_rounded,
                  color: isLocked ? AppTheme.darkTextMuted : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apps to Block',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isLocked
                          ? 'Selection Locked'
                          : '${blockedApps.length} app${blockedApps.length != 1 ? 's' : ''} selected',
                      style: TextStyle(
                        color: isLocked
                            ? AppTheme.dangerRed
                            : AppTheme.darkTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // App List
          // 🔒 Wrap list in IgnorePointer & Opacity if locked
          IgnorePointer(
            ignoring: isLocked,
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Column(
                children: SupportedApps.apps.map((app) {
                  final isBlocked = blockedApps.contains(app.packageName);
                  final usageMs = usageByApp[app.packageName] ?? 0;
                  final usageMinutes = (usageMs / 60000).round();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AppTile(
                      app: app,
                      isBlocked: isBlocked,
                      usageMinutes: usageMinutes,
                      onToggle: (enabled) {
                        HapticFeedback.selectionClick();
                        onToggle(app.packageName, enabled);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                    'Only short-form content (Reels, Shorts) will be blocked, not the entire app',
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final bool isBlocked;
  final int usageMinutes;
  final ValueChanged<bool> onToggle;

  const _AppTile({
    required this.app,
    required this.isBlocked,
    required this.usageMinutes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBlocked
            ? app.color.withValues(alpha: 0.1)
            : AppTheme.darkSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked
              ? app.color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // App Logo
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: isBlocked
                  ? [
                      BoxShadow(
                        color: app.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _AppIcon(app: app),
            ),
          ),

          const SizedBox(width: 14),

          // App Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: TextStyle(
                    color: isBlocked ? app.color : AppTheme.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: app.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        app.contentType,
                        style: TextStyle(
                          color: app.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (usageMinutes > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppTheme.darkTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${usageMinutes}m today',
                        style: const TextStyle(
                          color: AppTheme.darkTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Toggle Switch
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isBlocked,
              onChanged: onToggle,
              activeThumbColor: Colors.white,
              activeTrackColor: app.color,
              inactiveThumbColor: AppTheme.darkTextMuted,
              inactiveTrackColor: AppTheme.darkSurface,
              trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.transparent;
                }
                return Colors.white.withValues(alpha: 0.1);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Smart App Icon
class _AppIcon extends StatelessWidget {
  final AppInfo app;

  const _AppIcon({required this.app});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      app.iconPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          app.iconUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingState();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon();
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: app.color.withValues(alpha: 0.2),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: app.color,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    if (app.packageName == 'com.instagram.android') return _InstagramFallback();
    if (app.packageName == 'com.google.android.youtube') return _YouTubeFallback();
    return Container(
      color: app.color,
      child: Center(
        child: Text(
          app.name[0],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InstagramFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF833AB4),
            Color(0xFFF77737),
            Color(0xFFE1306C),
            Color(0xFFC13584),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YouTubeFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class AppInfo {
  final String name;
  final String packageName;
  final String contentType;
  final Color color;
  final String iconPath;
  final String iconUrl;

  const AppInfo({
    required this.name,
    required this.packageName,
    required this.contentType,
    required this.color,
    required this.iconPath,
    required this.iconUrl,
  });
}

class SupportedApps {
  static const List<AppInfo> apps = [
    AppInfo(
      name: 'Instagram',
      packageName: 'com.instagram.android',
      contentType: 'Reels',
      color: Color(0xFFE1306C),
      iconPath: 'assets/icons/instagram.png',
      iconUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Instagram_logo_2016.svg/132px-Instagram_logo_2016.svg.png',
    ),
    AppInfo(
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      contentType: 'Shorts',
      color: Color(0xFFFF0000),
      iconPath: 'assets/icons/youtube.png',
      iconUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/120px-YouTube_full-color_icon_%282017%29.svg.png',
    ),
  ];
}