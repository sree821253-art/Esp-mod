import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LightBrightnessControl extends StatelessWidget {
  final int brightness;
  final bool isOn;
  final ValueChanged<int> onBrightnessChanged;

  const LightBrightnessControl({
    super.key,
    required this.brightness,
    required this.isOn,
    required this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isOn ? const Color(0xFFFFEB3B) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Brightness',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeColor.withOpacity(0.5),
                ),
              ),
              child: Text(
                '$brightness%',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: isOn
                  ? () => onBrightnessChanged(
                        (brightness - 10).clamp(0, 100),
                      )
                  : null,
              color: activeColor,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: activeColor,
                  inactiveTrackColor: activeColor.withOpacity(0.2),
                  thumbColor: activeColor,
                  overlayColor: activeColor.withOpacity(0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                ),
                child: Slider(
                  value: brightness.toDouble(),
                  min: 0,
                  max: 100,
                  onChanged: isOn
                      ? (value) => onBrightnessChanged(value.round())
                      : null,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onTap: isOn
                  ? () => onBrightnessChanged(
                        (brightness + 10).clamp(0, 100),
                      )
                  : null,
              color: activeColor,
            ),
          ],
        ),
      ],
    );
  }
}

class FanSpeedControl extends StatelessWidget {
  final int speed;
  final bool isOn;
  final ValueChanged<int> onSpeedChanged;

  const FanSpeedControl({
    super.key,
    required this.speed,
    required this.isOn,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isOn ? AppTheme.neonCyan : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fan Speed',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: activeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activeColor.withOpacity(0.5),
                ),
              ),
              child: Text(
                'Level $speed',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onTap: isOn && speed > 1
                  ? () => onSpeedChanged(speed - 1)
                  : null,
              color: activeColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final level = index + 1;
                  final isSelected = speed == level;
                  return GestureDetector(
                    onTap: isOn ? () => onSpeedChanged(level) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : activeColor.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected && isDark
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: TextStyle(
                            color: isSelected
                                ? activeColor
                                : activeColor.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            _StepButton(
              icon: Icons.add,
              onTap: isOn && speed < 5
                  ? () => onSpeedChanged(speed + 1)
                  : null,
              color: activeColor,
            ),
          ],
        ),
      ],
    );
  }
}

class WaterLevelGauge extends StatefulWidget {
  final int waterLevel;
  final int minThreshold;
  final int maxThreshold;
  final bool isOn;
  final bool isRemoteMode;
  final VoidCallback? onManualOn;
  final VoidCallback? onManualOff;

  const WaterLevelGauge({
    super.key,
    required this.waterLevel,
    required this.minThreshold,
    required this.maxThreshold,
    required this.isOn,
    required this.isRemoteMode,
    this.onManualOn,
    this.onManualOff,
  });

  @override
  State<WaterLevelGauge> createState() => _WaterLevelGaugeState();
}

class _WaterLevelGaugeState extends State<WaterLevelGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Color _getWaterColor() {
    if (widget.waterLevel >= 98) {
      return AppTheme.neonRed;
    } else if (widget.waterLevel >= widget.maxThreshold) {
      return AppTheme.neonAmber;
    } else if (widget.waterLevel <= widget.minThreshold) {
      return AppTheme.neonRed;
    }
    return AppTheme.neonBlue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterColor = _getWaterColor();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular gauge
              SizedBox(
                width: 180,
                height: 180,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: WaterGaugePainter(
                        waterLevel: widget.waterLevel / 100,
                        minThreshold: widget.minThreshold / 100,
                        maxThreshold: widget.maxThreshold / 100,
                        waveProgress: _waveController.value,
                        waterColor: waterColor,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.waterLevel}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: waterColor,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: waterColor.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Text(
                    widget.isOn ? 'FILLING' : 'IDLE',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Threshold indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ThresholdIndicator(
              label: 'MIN',
              value: widget.minThreshold,
              color: AppTheme.neonRed,
              isActive: widget.waterLevel <= widget.minThreshold,
              isDark: isDark,
            ),
            _ThresholdIndicator(
              label: 'MAX',
              value: widget.maxThreshold,
              color: AppTheme.neonGreen,
              isActive: widget.waterLevel >= widget.maxThreshold,
              isDark: isDark,
            ),
          ],
        ),
        if (widget.isRemoteMode) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onManualOn,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Manual ON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen.withOpacity(0.2),
                    foregroundColor: AppTheme.neonGreen,
                    side: const BorderSide(color: AppTheme.neonGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onManualOff,
                  icon: const Icon(Icons.stop),
                  label: const Text('Manual OFF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonRed.withOpacity(0.2),
                    foregroundColor: AppTheme.neonRed,
                    side: const BorderSide(color: AppTheme.neonRed),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (widget.waterLevel >= 98)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonRed),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: AppTheme.neonRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EMERGENCY STOP ACTIVE',
                    style: TextStyle(
                      color: AppTheme.neonRed,
                      fontWeight: FontWeight.bold,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: AppTheme.neonRed.withOpacity(0.5),
                                blurRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class WaterGaugePainter extends CustomPainter {
  final double waterLevel;
  final double minThreshold;
  final double maxThreshold;
  final double waveProgress;
  final Color waterColor;
  final bool isDark;

  WaterGaugePainter({
    required this.waterLevel,
    required this.minThreshold,
    required this.maxThreshold,
    required this.waveProgress,
    required this.waterColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = isDark
          ? AppTheme.circuitLine.withOpacity(0.5)
          : Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Water fill
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    final waterHeight = size.height * (1 - waterLevel);
    final waterPath = Path();
    waterPath.moveTo(0, size.height);

    // Wave effect
    for (double x = 0; x <= size.width; x++) {
      final waveOffset =
          math.sin((x / size.width * 2 * math.pi) + (waveProgress * 2 * math.pi)) * 5;
      waterPath.lineTo(x, waterHeight + waveOffset);
    }

    waterPath.lineTo(size.width, size.height);
    waterPath.close();

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterColor.withOpacity(0.6),
          waterColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(waterPath, waterPaint);
    canvas.restore();

    // Border glow
    final borderPaint = Paint()
      ..color = waterColor.withOpacity(isDark ? 0.5 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (isDark) {
      borderPaint.maskFilter =
          const MaskFilter.blur(BlurStyle.outer, 5);
    }
    canvas.drawCircle(center, radius, borderPaint);

    // Threshold markers
    _drawThresholdMarker(canvas, center, radius, minThreshold, AppTheme.neonRed);
    _drawThresholdMarker(canvas, center, radius, maxThreshold, AppTheme.neonGreen);
  }

  void _drawThresholdMarker(
    Canvas canvas,
    Offset center,
    double radius,
    double threshold,
    Color color,
  ) {
    final y = center.dy + radius - (threshold * radius * 2);
    final markerPaint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx - radius + 5, y),
      Offset(center.dx - radius + 15, y),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius - 15, y),
      Offset(center.dx + radius - 5, y),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WaterGaugePainter oldDelegate) {
    return oldDelegate.waterLevel != waterLevel ||
        oldDelegate.waveProgress != waveProgress;
  }
}

class _ThresholdIndicator extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isActive;
  final bool isDark;

  const _ThresholdIndicator({
    required this.label,
    required this.value,
    required this.color,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(isActive ? 1 : 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$value%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class GasSensorDisplay extends StatelessWidget {
  final double lpgValue;
  final double coValue;
  final double lpgThreshold;
  final double coThreshold;

  const GasSensorDisplay({
    super.key,
    required this.lpgValue,
    required this.coValue,
    this.lpgThreshold = 50,
    this.coThreshold = 25,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _GasValueCard(
          label: 'LPG Level',
          value: lpgValue,
          unit: 'ppm',
          maxValue: 100,
          threshold: lpgThreshold,
          color: lpgValue > lpgThreshold
              ? AppTheme.neonRed
              : AppTheme.neonAmber,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _GasValueCard(
          label: 'CO Level',
          value: coValue,
          unit: 'ppm',
          maxValue: 50,
          threshold: coThreshold,
          color: coValue > coThreshold
              ? AppTheme.neonRed
              : AppTheme.neonGreen,
          isDark: isDark,
        ),
        if (lpgValue > lpgThreshold || coValue > coThreshold)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonRed),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: AppTheme.neonRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GAS DETECTED - VENTILATE AREA',
                    style: TextStyle(
                      color: AppTheme.neonRed,
                      fontWeight: FontWeight.bold,
                      shadows: isDark
                          ? [
                              Shadow(
                                color: AppTheme.neonRed.withOpacity(0.5),
                                blurRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GasValueCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double maxValue;
  final double threshold;
  final Color color;
  final bool isDark;

  const _GasValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.maxValue,
    required this.threshold,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    final thresholdProgress = (threshold / maxValue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.circuitDarkAlt.withOpacity(0.5)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value > threshold
              ? AppTheme.neonRed.withOpacity(0.5)
              : color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Value bar
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              // Threshold marker
              Positioned(
                left: thresholdProgress *
                    (MediaQuery.of(context).size.width - 96),
                child: Container(
                  width: 2,
                  height: 8,
                  color: AppTheme.neonRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Threshold: ${threshold.toStringAsFixed(0)} $unit',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null
                ? color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? color : Colors.grey,
        ),
      ),
    );
  }
}

class DevicePowerToggle extends StatelessWidget {
  final bool isOn;
  final bool isOnline;
  final bool isLoading;
  final VoidCallback? onToggle;
  final Color? activeColor;

  const DevicePowerToggle({
    super.key,
    required this.isOn,
    required this.isOnline,
    this.isLoading = false,
    this.onToggle,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeBrightness = Theme.of(context).brightness;
    final color = activeColor ?? AppTheme.neonCyan;
    final effectiveColor = isOnline
        ? (isOn ? color : Colors.grey)
        : Colors.red.withOpacity(0.5);

    return GestureDetector(
      onTap: isOnline && !isLoading ? onToggle : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor.withOpacity(isOn ? 0.2 : 0.1),
          border: Border.all(
            color: effectiveColor.withOpacity(isOn ? 1 : 0.5),
            width: 2,
          ),
          boxShadow: isOn && themeBrightness == Brightness.dark
              ? [
                  BoxShadow(
                    color: effectiveColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(effectiveColor),
                  ),
                ),
              )
            : Icon(
                Icons.power_settings_new,
                size: 40,
                color: effectiveColor,
              ),
      ),
    );
  }
}
