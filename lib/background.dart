import 'package:flutter/material.dart';

class RadialGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final double radius;
  final AlignmentGeometry centerAlignment;

  const RadialGradientBackground({
    super.key,
    required this.child,
    this.colors = const [Color(0xFF000000), Color(0XFF9752C5)],
    this.radius = 1.0,
    this.centerAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: centerAlignment,
          radius: radius,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
