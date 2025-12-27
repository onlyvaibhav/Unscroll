import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class QuickActionsCard extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onRefresh;
  final VoidCallback onPauseResume;
  final VoidCallback onShare;
  final VoidCallback onFocusMode;

  const QuickActionsCard({
    super.key,
    required this.isPaused,
    required this.onRefresh,
    required this.onPauseResume,
    required this.onShare,
    required this.onFocusMode,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Text('⚡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  color: AppTheme.accentCyan,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onRefresh();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: isPaused ? 'Resume' : 'Pause',
                  color: isPaused ? AppTheme.successGreen : AppTheme.warningOrange,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onPauseResume();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.self_improvement_rounded,
                  label: 'Focus',
                  color: AppTheme.primaryPurple,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onFocusMode();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: AppTheme.accentPink,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onShare();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_isPressed ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: widget.color,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}