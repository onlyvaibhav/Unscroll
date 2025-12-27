import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/animated_counter.dart';

class StatsCard extends StatefulWidget {
  final int usedMinutes;
  final int limitMinutes;
  final int remainingMinutes;
  final double usagePercentage;
  final VoidCallback? onReset;

  const StatsCard({
    super.key,
    required this.usedMinutes,
    required this.limitMinutes,
    required this.remainingMinutes,
    required this.usagePercentage,
    this.onReset,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  bool _hasShownConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(StatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Show confetti when user stays under 50% limit
    if (widget.usedMinutes > 0 && 
        widget.usagePercentage < 0.5 && 
        oldWidget.usagePercentage >= 0.5 &&
        !_hasShownConfetti) {
      _confettiController.play();
      _hasShownConfetti = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOverLimit = widget.usagePercentage >= 1;
    final isNearLimit = widget.usagePercentage >= 0.8;
    final isWarning = widget.usagePercentage >= 0.6;

    // Determine colors and status
    Color progressColor;
    Gradient progressGradient;
    String statusText;
    String statusEmoji;

    if (isOverLimit) {
      progressColor = AppTheme.dangerRed;
      progressGradient = AppTheme.dangerGradient;
      statusText = 'Limit Reached!';
      statusEmoji = '🛑';
    } else if (isNearLimit) {
      progressColor = AppTheme.dangerRed;
      progressGradient = const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
      );
      statusText = 'Almost there!';
      statusEmoji = '⚠️';
    } else if (isWarning) {
      progressColor = AppTheme.warningOrange;
      progressGradient = const LinearGradient(
        colors: [Color(0xFFFFAB00), Color(0xFFFF8C00)],
      );
      statusText = '${widget.remainingMinutes}m remaining';
      statusEmoji = '⏰';
    } else {
      progressColor = AppTheme.successGreen;
      progressGradient = AppTheme.successGradient;
      statusText = 'Looking good!';
      statusEmoji = '✨';
    }

    return Stack(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🎯',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Today's Focus",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: progressColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(statusEmoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2.seconds,
                      color: isNearLimit ? progressColor.withOpacity(0.3) : Colors.transparent,
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // Circular Progress
              AnimatedCircularProgress(
                progress: widget.usagePercentage,
                size: 200,
                strokeWidth: 14,
                progressColor: progressColor,
                backgroundColor: AppTheme.darkSurfaceLight,
                gradient: progressGradient,
                showPulse: isNearLimit || isOverLimit,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main number
                    ShaderMask(
                      shaderCallback: (bounds) => progressGradient.createShader(bounds),
                      child: Text(
                        '${widget.usedMinutes}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      'of ${widget.limitMinutes} min',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Percentage
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedPercentage(
                        value: widget.usagePercentage.clamp(0, 1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Stats Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.timer_outlined,
                        label: 'Used',
                        value: _formatTime(widget.usedMinutes),
                        color: progressColor,
                        iconBgColor: progressColor.withOpacity(0.15),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.hourglass_empty_rounded,
                        label: 'Left',
                        value: _formatTime(widget.remainingMinutes),
                        color: AppTheme.successGreen,
                        iconBgColor: AppTheme.successGreen.withOpacity(0.15),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.flag_rounded,
                        label: 'Limit',
                        value: _formatTime(widget.limitMinutes),
                        color: AppTheme.primaryPurple,
                        iconBgColor: AppTheme.primaryPurple.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

              // Reset Button
              if (widget.onReset != null && widget.usedMinutes > 0) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: widget.onReset,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppTheme.darkTextMuted,
                  ),
                  label: const Text(
                    'Reset Today',
                    style: TextStyle(
                      color: AppTheme.darkTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ],
          ),
        ),

        // Confetti
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                AppTheme.successGreen,
                AppTheme.primaryPurple,
                AppTheme.accentCyan,
                AppTheme.accentPink,
                Colors.yellow,
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconBgColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.darkTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}