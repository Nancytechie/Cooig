import 'dart:math';
import 'package:flutter/material.dart';

class RotatingCircles extends StatefulWidget {
  const RotatingCircles({super.key});

  @override
  _RotatingCirclesState createState() => _RotatingCirclesState();
}

class _RotatingCirclesState extends State<RotatingCircles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating circles with beads
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Inner dashed circle
                CustomPaint(
                  size: const Size(300, 300),
                  painter: DashedCirclePainter(Colors.white, 2.0, radius: 100),
                ),
                // Outer dashed circle
                Transform.rotate(
                  angle: _controller.value * 2 * pi,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter:
                        DashedCirclePainter(Colors.white, 4.0, radius: 150),
                  ),
                ),
                // Beads on the inner circle
                ...List.generate(4, (index) {
                  final angle = index * pi / 2; // 4 points equally spaced
                  final x = 150 +
                      150 * cos(angle) -
                      10; // Position calculation for beads
                  final y = 150 + 150 * sin(angle) - 10;
                  return Positioned(
                    top: y,
                    left: x,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        // Static profile pictures on the outer orbit
        ...List.generate(4, (index) {
          final angle = index * pi / 2; // 4 points equally spaced
          final x = 150 +
              150 * cos(angle) -
              20; // Position calculation for profile pictures
          final y = 150 + 150 * sin(angle) - 20;
          return Positioned(
            top: y,
            left: x,
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/profile${index + 1}.png'),
              radius: 20,
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  DashedCirclePainter(this.color, this.strokeWidth, {this.radius = 150});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = size.center(Offset.zero);
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final start = distance;
        final end = start + dashWidth;
        final extractPath = pathMetric.extractPath(start, end);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
