import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CircuitBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  const CircuitBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<CircuitBackground> createState() => _CircuitBackgroundState();
}

class _CircuitBackgroundState extends State<CircuitBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      // Light mode - Glassmorphism background
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4FD),
              Color(0xFFF0F4F8),
              Color(0xFFE1E8ED),
            ],
          ),
        ),
        child: widget.child,
      );
    }

    // Dark mode - Circuit board background
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CircuitPainter(
            progress: _controller.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class CircuitPainter extends CustomPainter {
  final double progress;

  CircuitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = AppTheme.circuitDark
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Circuit lines paint
    final linePaint = Paint()
      ..color = AppTheme.circuitLine.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final glowPaint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);

    final nodePaint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent pattern
    final gridSize = 40.0;

    // Draw grid lines
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        // Horizontal traces
        if (random.nextDouble() > 0.6) {
          final path = Path();
          path.moveTo(x, y);

          if (random.nextBool()) {
            path.lineTo(x + gridSize * 0.5, y);
            path.lineTo(x + gridSize * 0.5, y + gridSize * 0.3);
            path.lineTo(x + gridSize, y + gridSize * 0.3);
          } else {
            path.lineTo(x + gridSize, y);
          }

          canvas.drawPath(path, linePaint);

          // Add glow effect on some lines
          if (random.nextDouble() > 0.8) {
            final glowProgress =
                (progress + x / size.width + y / size.height) % 1.0;
            final glowOpacity =
                (math.sin(glowProgress * math.pi * 2) * 0.5 + 0.5);
            glowPaint.color =
                AppTheme.neonCyan.withOpacity(0.3 * glowOpacity);
            canvas.drawPath(path, glowPaint);
          }
        }

        // Vertical traces
        if (random.nextDouble() > 0.7) {
          final path = Path();
          path.moveTo(x, y);
          path.lineTo(x, y + gridSize);
          canvas.drawPath(path, linePaint);
        }

        // Nodes at intersections
        if (random.nextDouble() > 0.85) {
          final nodeSize = 3.0 + random.nextDouble() * 3;
          canvas.drawCircle(Offset(x, y), nodeSize, nodePaint);

          // Pulsing glow on some nodes
          if (random.nextDouble() > 0.5) {
            final pulseProgress =
                (progress * 2 + x / size.width) % 1.0;
            final pulseOpacity =
                (math.sin(pulseProgress * math.pi * 2) * 0.5 + 0.5);
            final pulseGlow = Paint()
              ..color = AppTheme.neonCyan.withOpacity(0.5 * pulseOpacity)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
            canvas.drawCircle(Offset(x, y), nodeSize + 4, pulseGlow);
          }
        }

        // IC chip shapes
        if (random.nextDouble() > 0.95) {
          final chipPaint = Paint()
            ..color = AppTheme.circuitLine.withOpacity(0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;

          final chipRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, gridSize * 0.8, gridSize * 0.5),
            const Radius.circular(2),
          );
          canvas.drawRRect(chipRect, chipPaint);

          // Chip pins
          for (int i = 0; i < 4; i++) {
            canvas.drawLine(
              Offset(x + gridSize * 0.15 + i * gridSize * 0.15, y),
              Offset(
                  x + gridSize * 0.15 + i * gridSize * 0.15, y - 5),
              linePaint,
            );
            canvas.drawLine(
              Offset(x + gridSize * 0.15 + i * gridSize * 0.15,
                  y + gridSize * 0.5),
              Offset(x + gridSize * 0.15 + i * gridSize * 0.15,
                  y + gridSize * 0.5 + 5),
              linePaint,
            );
          }
        }
      }
    }

    // Corner accent circuits
    _drawCornerAccent(canvas, size, Offset.zero, 1, 1);
    _drawCornerAccent(
        canvas, size, Offset(size.width, 0), -1, 1);
    _drawCornerAccent(
        canvas, size, Offset(0, size.height), 1, -1);
    _drawCornerAccent(
        canvas, size, Offset(size.width, size.height), -1, -1);
  }

  void _drawCornerAccent(
    Canvas canvas,
    Size size,
    Offset corner,
    double xDir,
    double yDir,
  ) {
    final paint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final glowPaint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

    for (int i = 0; i < 3; i++) {
      final offset = 20.0 + i * 15.0;
      final path = Path();
      path.moveTo(corner.dx + xDir * offset, corner.dy);
      path.lineTo(corner.dx + xDir * offset, corner.dy + yDir * offset);
      path.lineTo(corner.dx, corner.dy + yDir * offset);

      canvas.drawPath(path, paint);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CircuitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool glowEffect;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.glowEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.circuitDarkAlt.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.neonCyan.withOpacity(glowEffect ? 0.5 : 0.2)
              : Colors.white.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          if (glowEffect && isDark)
            BoxShadow(
              color: AppTheme.neonCyan.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }

    return card;
  }
}

class NeonText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? glowColor;
  final double glowRadius;

  const NeonText({
    super.key,
    required this.text,
    this.style,
    this.glowColor,
    this.glowRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = glowColor ?? AppTheme.neonCyan;

    if (!isDark) {
      return Text(text, style: style);
    }

    return Stack(
      children: [
        Text(
          text,
          style: (style ?? const TextStyle()).copyWith(
            foreground: Paint()
              ..color = color.withOpacity(0.5)
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowRadius),
          ),
        ),
        Text(
          text,
          style: (style ?? const TextStyle()).copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}

class NeonIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final bool glow;

  const NeonIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? AppTheme.neonCyan;

    if (!isDark || !glow) {
      return Icon(icon, size: size, color: iconColor);
    }

    return Stack(
      children: [
        Icon(
          icon,
          size: size,
          color: iconColor.withOpacity(0.5),
        ),
        Icon(
          icon,
          size: size,
          color: iconColor,
          shadows: [
            Shadow(
              color: iconColor.withOpacity(0.8),
              blurRadius: 15,
            ),
          ],
        ),
      ],
    );
  }
}

class NeonDivider extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;

  const NeonDivider({
    super.key,
    this.height = 1,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.transparent,
                  AppTheme.neonCyan.withOpacity(0.5),
                  AppTheme.neonCyan,
                  AppTheme.neonCyan.withOpacity(0.5),
                  Colors.transparent,
                ]
              : [
                  Colors.transparent,
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.3),
                  Colors.transparent,
                ],
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withOpacity(0.3),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}
