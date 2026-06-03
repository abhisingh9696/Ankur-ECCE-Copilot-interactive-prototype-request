import 'dart:math';
import 'package:flutter/material.dart';
import '../models/child_model.dart';

class NcfRadarChart extends StatelessWidget {
  final Map<String, double> data;
  final String language;
  final double size;

  const NcfRadarChart({
    super.key,
    required this.data,
    required this.language,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          data: data,
          language: language,
          domains: ncfDomains,
        ),
        size: Size(size, size),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> data;
  final String language;
  final List<NcfDomain> domains;

  _RadarPainter({
    required this.data,
    required this.language,
    required this.domains,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final n = domains.length;
    final angleStep = (2 * pi) / n;
    const startAngle = -pi / 2;

    // Draw background webs (4 levels)
    final webPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final webDashPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= 4; level++) {
      final r = radius * level / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = startAngle + angleStep * i;
        final point = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, level == 4 ? webPaint : webDashPaint);
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        axisPaint,
      );
    }

    // Draw data polygon
    final dataPath = Path();
    final dataPoints = <Offset>[];
    final fillPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < n; i++) {
      final domain = domains[i];
      final value = (data[domain.id] ?? 0.1).clamp(0.1, 1.0);
      final angle = startAngle + angleStep * i;
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );
      dataPoints.add(point);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw data points
    final dotPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    for (final point in dataPoints) {
      canvas.drawCircle(point, 4.5, dotPaint);
      canvas.drawCircle(
          point, 4.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Draw labels
    for (int i = 0; i < n; i++) {
      final domain = domains[i];
      final angle = startAngle + angleStep * i;
      final labelR = radius + 24;
      final x = center.dx + labelR * cos(angle);
      final y = center.dy + labelR * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: domain.label(language),
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: 80);
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
