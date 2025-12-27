import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class TimeLimitCard extends StatefulWidget {
  final int currentLimit;
  final ValueChanged<int> onLimitChanged;
  final bool isLocked;

  const TimeLimitCard({
    super.key,
    required this.currentLimit,
    required this.onLimitChanged,
    this.isLocked = false,
  });

  @override
  State<TimeLimitCard> createState() => _TimeLimitCardState();
}

class _TimeLimitCardState extends State<TimeLimitCard> {
  late double _sliderValue;
  final List<int> _presets = [5, 15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentLimit.toDouble();
  }

  @override
  void didUpdateWidget(TimeLimitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLimit != widget.currentLimit) {
      _sliderValue = widget.currentLimit.toDouble();
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
    return '${hours}h ${mins}m';
  }

  Color _getLimitColor(int minutes) {
    if (widget.isLocked) return AppTheme.darkTextMuted;
    if (minutes <= 15) return AppTheme.successGreen;
    if (minutes <= 30) return AppTheme.accentCyan;
    if (minutes <= 60) return AppTheme.primaryPurple;
    if (minutes <= 90) return AppTheme.warningOrange;
    return AppTheme.dangerRed;
  }

  @override
  Widget build(BuildContext context) {
    final limitColor = _getLimitColor(_sliderValue.round());

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
                  color: limitColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isLocked ? Icons.lock_rounded : Icons.timer_rounded,
                  color: limitColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Limit',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      widget.isLocked 
                          ? 'Locked by Strict Mode' 
                          : 'Time allowed for Shorts & Reels',
                      style: TextStyle(
                        color: widget.isLocked 
                            ? AppTheme.dangerRed 
                            : AppTheme.darkTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Current Value Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: widget.isLocked 
                      ? null 
                      : LinearGradient(
                          colors: [limitColor, limitColor.withValues(alpha: 0.8)],
                        ),
                  color: widget.isLocked ? AppTheme.darkSurfaceLight : null,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isLocked 
                      ? Border.all(color: AppTheme.darkTextMuted.withValues(alpha: 0.3))
                      : [
                          BoxShadow(
                            color: limitColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ].isEmpty ? null : null, // Trick to handle dynamic decoration
                  boxShadow: !widget.isLocked ? [
                    BoxShadow(
                      color: limitColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(_sliderValue.round()),
                      style: TextStyle(
                        color: widget.isLocked ? AppTheme.darkTextMuted : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.isLocked) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_outline, size: 14, color: AppTheme.darkTextMuted),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Custom Slider
          IgnorePointer(
            ignoring: widget.isLocked,
            child: Opacity(
              opacity: widget.isLocked ? 0.5 : 1.0,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: limitColor,
                  inactiveTrackColor: AppTheme.darkSurfaceLight,
                  thumbColor: widget.isLocked ? AppTheme.darkTextMuted : Colors.white,
                  overlayColor: limitColor.withValues(alpha: 0.2),
                  trackHeight: 10,
                  thumbShape: _CustomThumbShape(color: limitColor),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                  trackShape: _CustomTrackShape(),
                ),
                child: Slider(
                  value: _sliderValue,
                  min: 1,
                  max: 120,
                  divisions: 119,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _sliderValue = value;
                    });
                  },
                  onChangeEnd: (value) {
                    HapticFeedback.mediumImpact();
                    widget.onLimitChanged(value.round());
                  },
                ),
              ),
            ),
          ),

          // Min/Max Labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 min',
                  style: TextStyle(
                    color: AppTheme.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '2 hours',
                  style: TextStyle(
                    color: AppTheme.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Only show presets/tip if NOT locked
          if (!widget.isLocked) ...[
            const SizedBox(height: 20),

            // Preset Buttons
            const Text(
              'Quick Presets',
              style: TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _sliderValue.round() == preset;
                final presetColor = _getLimitColor(preset);
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _sliderValue = preset.toDouble();
                    });
                    widget.onLimitChanged(preset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? presetColor.withValues(alpha: 0.2)
                          : AppTheme.darkSurfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? presetColor
                            : Colors.white.withValues(alpha: 0.05),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      _formatDuration(preset),
                      style: TextStyle(
                        color: isSelected ? presetColor : AppTheme.darkTextSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.primaryPurple,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: Start with a smaller limit and gradually adjust',
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
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
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }
}

// Custom Thumb Shape
class _CustomThumbShape extends SliderComponentShape {
  final Color color;

  const _CustomThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 14, glowPaint);

    // White circle
    final thumbPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, thumbPaint);

    // Inner colored circle
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, innerPaint);
  }
}

// Custom Track Shape
class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 10;
    final trackLeft = offset.dx + 12;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 24;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}