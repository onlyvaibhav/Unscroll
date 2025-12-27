import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum ConfirmationType {
  warning,  // Orange - for caution
  danger,   // Red - for destructive actions
  critical, // Dark red with pulse - for limit reached actions
}

class SeriousConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? additionalInfo;
  final String confirmText;
  final String cancelText;
  final ConfirmationType type;
  final IconData icon;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const SeriousConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.additionalInfo,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.type = ConfirmationType.warning,
    this.icon = Icons.warning_amber_rounded,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<SeriousConfirmDialog> createState() => _SeriousConfirmDialogState();
}

class _SeriousConfirmDialogState extends State<SeriousConfirmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.type == ConfirmationType.critical) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    switch (widget.type) {
      case ConfirmationType.warning:
        return AppTheme.warningOrange;
      case ConfirmationType.danger:
        return AppTheme.dangerRed;
      case ConfirmationType.critical:
        return const Color(0xFFDC2626); // Darker red
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _primaryColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.type == ConfirmationType.critical
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: widget.type == ConfirmationType.critical
                          ? [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.icon,
                      color: _primaryColor,
                      size: 36,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),

            // Additional Info (if provided)
            if (widget.additionalInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.additionalInfo!,
                        style: TextStyle(
                          color: _primaryColor.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, false);
                      widget.onCancel?.call();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Text(
                      widget.cancelText,
                      style: const TextStyle(
                        color: AppTheme.darkTextSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Confirm Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(context, true);
                      widget.onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.confirmText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          begin: const Offset(0.9, 0.9),
          curve: Curves.easeOutBack,
        );
  }
}

// Helper function to show serious confirmation
Future<bool> showSeriousConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String? additionalInfo,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  ConfirmationType type = ConfirmationType.warning,
  IconData icon = Icons.warning_amber_rounded,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => SeriousConfirmDialog(
      title: title,
      message: message,
      additionalInfo: additionalInfo,
      confirmText: confirmText,
      cancelText: cancelText,
      type: type,
      icon: icon,
      onConfirm: () {},
    ),
  );
  return result ?? false;
}

// Specific dialog for limit-reached situations
Future<bool> showLimitReachedWarning(
  BuildContext context, {
  required String action,
}) async {
  return await showSeriousConfirmation(
    context,
    title: '⚠️ Limit Reached!',
    message: 'Your daily limit has been reached. Changing settings now may defeat the purpose of blocking.',
    additionalInfo: 'You\'re trying to: $action',
    confirmText: 'I Understand',
    cancelText: 'Go Back',
    type: ConfirmationType.critical,
    icon: Icons.shield_rounded,
  );
}

// Dialog for strict mode toggle
Future<bool> showStrictModeWarning(
  BuildContext context, {
  required bool enabling,
}) async {
  if (enabling) {
    return await showSeriousConfirmation(
      context,
      title: 'Enable Strict Mode?',
      message: 'Once enabled, you won\'t be able to:\n• Reset daily usage\n• Change time limits easily\n• Bypass the blocker',
      additionalInfo: 'PIN verification will be required for any changes',
      confirmText: 'Enable Strict',
      cancelText: 'Not Now',
      type: ConfirmationType.warning,
      icon: Icons.lock_rounded,
    );
  } else {
    return await showSeriousConfirmation(
      context,
      title: 'Disable Strict Mode?',
      message: 'Are you sure you want to disable strict mode? This will make it easier to bypass blocking.',
      confirmText: 'Yes, Disable',
      cancelText: 'Keep It On',
      type: ConfirmationType.danger,
      icon: Icons.lock_open_rounded,
    );
  }
}