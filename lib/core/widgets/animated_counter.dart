import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, val, child) {
        return Text(
          '$val',
          style: style,
        );
      },
    );
  }
}

// Animated percentage counter
class AnimatedPercentage extends StatelessWidget {
  final double value;
  final TextStyle? style;

  const AnimatedPercentage({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '${(val * 100).toInt()}%',
          style: style,
        );
      },
    );
  }
}

// Pulsing widget for danger state
class PulsingWidget extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color pulseColor;

  const PulsingWidget({
    super.key,
    required this.child,
    this.isPulsing = true,
    this.pulseColor = Colors.red,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.pulseColor.withOpacity(0.3 * (_animation.value - 1) * 6.67),
                  blurRadius: 30 * (_animation.value - 1) * 6.67,
                  spreadRadius: 10 * (_animation.value - 1) * 6.67,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Animated circular progress with gradient
class AnimatedCircularProgress extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Gradient? gradient;
  final Widget? child;
  final bool showPulse;

  const AnimatedCircularProgress({
    super.key,
    required this.progress,
    this.size = 200,
    this.strokeWidth = 12,
    this.progressColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.gradient,
    this.child,
    this.showPulse = false,
  });

  @override
  State<AnimatedCircularProgress> createState() => _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.showPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.progress.clamp(0, 1)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final pulseValue = widget.showPulse 
                ? 0.3 * _pulseController.value 
                : 0.0;
            
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: widget.showPulse
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.progressColor.withOpacity(pulseValue),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    )
                  : null,
              child: CustomPaint(
                painter: _GradientCircularProgressPainter(
                  progress: animatedProgress,
                  strokeWidth: widget.strokeWidth,
                  progressColor: widget.progressColor,
                  backgroundColor: widget.backgroundColor,
                  gradient: widget.gradient,
                ),
                child: Center(child: widget.child),
              ),
            );
          },
        );
      },
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Gradient? gradient;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      progressPaint.shader = gradient!.createShader(rect);
    } else {
      progressPaint.color = progressColor;
    }

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}