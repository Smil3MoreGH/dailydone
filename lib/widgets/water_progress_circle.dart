import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/water_entry.dart';
import '../models/beverage_type.dart';

class WaterProgressCircle extends StatelessWidget {
  final int currentAmount;
  final int goalAmount;
  final List<WaterEntry> entries;

  const WaterProgressCircle({
    super.key,
    required this.currentAmount,
    required this.goalAmount,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentAmount / goalAmount).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate segments for each beverage type
    final segments = _calculateSegments();

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: const Size(280, 280),
            painter: CircularProgressPainter(
              progress: 1.0,
              segments: const [],
              backgroundColor: isDark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFF0F0F0),
            ),
          ),
          // Progress segments
          CustomPaint(
            size: const Size(280, 280),
            painter: CircularProgressPainter(
              progress: progress,
              segments: segments,
              backgroundColor: Colors.transparent,
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(currentAmount / 1000).toStringAsFixed(1)}L',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'of ${(goalAmount / 1000).toStringAsFixed(1)}L',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(progress).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(progress),
                  style: TextStyle(
                    color: _getStatusColor(progress),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ProgressSegment> _calculateSegments() {
    if (entries.isEmpty) return [];

    final segments = <ProgressSegment>[];
    double startAngle = -math.pi / 2; // Start from top

    for (final entry in entries.reversed) {
      final segmentProgress = entry.amount / goalAmount;
      segments.add(ProgressSegment(
        startAngle: startAngle,
        sweepAngle: segmentProgress * 2 * math.pi,
        color: entry.type.color,
      ));
      startAngle += segmentProgress * 2 * math.pi;
    }

    return segments;
  }

  Color _getStatusColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(double progress) {
    if (progress >= 1.0) return 'Goal Reached! 🎉';
    if (progress >= 0.7) return 'Almost There!';
    if (progress >= 0.4) return 'Keep Going!';
    return 'Stay Hydrated';
  }
}

class ProgressSegment {
  final double startAngle;
  final double sweepAngle;
  final Color color;

  ProgressSegment({
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
  });
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final List<ProgressSegment> segments;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.segments,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final strokeWidth = 20.0;

    // Draw background
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, backgroundPaint);
    }

    // Draw segments
    for (final segment in segments) {
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        segment.startAngle,
        segment.sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}