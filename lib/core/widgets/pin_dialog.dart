import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

enum PinDialogMode { setup, verify, change }

class PinDialog extends StatefulWidget {
  final PinDialogMode mode;
  final String title;
  final String subtitle;
  final Future<bool> Function(String pin) onVerify;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PinDialog({
    super.key,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.onVerify,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // For setup mode - confirm PIN
  bool _isConfirmStep = false;
  String _firstPin = '';

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onPinCompleted(String pin) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    HapticFeedback.mediumImpact();

    // Setup mode - need to confirm PIN
    if (widget.mode == PinDialogMode.setup && !_isConfirmStep) {
      setState(() {
        _firstPin = pin;
        _isConfirmStep = true;
        _isLoading = false;
        _pinController.clear();
      });
      return;
    }

    // Setup mode - confirm step
    if (widget.mode == PinDialogMode.setup && _isConfirmStep) {
      if (pin != _firstPin) {
        _showError("PINs don't match. Try again.");
        setState(() {
          _isConfirmStep = false;
          _firstPin = '';
        });
        return;
      }
    }

    // Verify the PIN
    final success = await widget.onVerify(pin);

    if (success) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSuccess?.call();
      }
    } else {
      _showError('Incorrect PIN. Try again.');
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) => _shakeController.reset());
    
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
      _pinController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentTitle = widget.title;
    String currentSubtitle = widget.subtitle;

    if (widget.mode == PinDialogMode.setup) {
      if (_isConfirmStep) {
        currentTitle = 'Confirm PIN';
        currentSubtitle = 'Enter the same PIN again';
      } else {
        currentTitle = 'Set New PIN';
        currentSubtitle = 'Create a 4-digit PIN';
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _hasError 
                    ? AppTheme.dangerGradient 
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _hasError 
                    ? AppTheme.dangerGlow 
                    : AppTheme.primaryGlow,
              ),
              child: Icon(
                _hasError ? Icons.lock_outline : Icons.lock_rounded,
                color: Colors.white,
                size: 32,
              ),
            ).animate(
              controller: _shakeController,
              autoPlay: false,
            ).shake(hz: 4, offset: const Offset(10, 0)),

            const SizedBox(height: 24),

            // Title
            Text(
              currentTitle,
              style: const TextStyle(
                color: AppTheme.darkText,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              currentSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            // PIN Input
            SizedBox(
              width: 240,
              child: PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _pinController,
                focusNode: _focusNode,
                obscureText: true,
                obscuringCharacter: '●',
                animationType: AnimationType.scale,
                keyboardType: TextInputType.number,
                autoFocus: true,
                enableActiveFill: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(14),
                  fieldHeight: 56,
                  fieldWidth: 52,
                  activeFillColor: AppTheme.darkSurfaceLight,
                  inactiveFillColor: AppTheme.darkSurfaceLight.withOpacity(0.5),
                  selectedFillColor: AppTheme.primaryPurple.withOpacity(0.1),
                  activeColor: _hasError ? AppTheme.dangerRed : AppTheme.primaryPurple,
                  inactiveColor: Colors.white.withOpacity(0.1),
                  selectedColor: AppTheme.primaryPurple,
                  errorBorderColor: AppTheme.dangerRed,
                ),
                cursorColor: AppTheme.primaryPurple,
                animationDuration: const Duration(milliseconds: 200),
                textStyle: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                onCompleted: _onPinCompleted,
                onChanged: (value) {
                  if (_hasError) {
                    setState(() => _hasError = false);
                  }
                },
              ),
            ),

            // Error Message
            if (_hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.dangerRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.dangerRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: AppTheme.dangerRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shake(hz: 2, offset: const Offset(5, 0)),
            ],

            // Loading indicator
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Cancel Button
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(false);
                widget.onCancel?.call();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.darkTextSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

// Helper function to show PIN dialog
Future<bool> showPinVerificationDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Future<bool> Function(String pin) onVerify,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => PinDialog(
      mode: PinDialogMode.verify,
      title: title,
      subtitle: subtitle,
      onVerify: onVerify,
    ),
  );
  return result ?? false;
}

Future<bool> showPinSetupDialog(
  BuildContext context, {
  required Future<bool> Function(String pin) onSetup,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => PinDialog(
      mode: PinDialogMode.setup,
      title: 'Set PIN',
      subtitle: 'Create a 4-digit PIN',
      onVerify: onSetup,
    ),
  );
  return result ?? false;
}