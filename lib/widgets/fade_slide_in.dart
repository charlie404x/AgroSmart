import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Entrada sutil (desvanecido + desplazamiento) con retraso escalonado por índice.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 16});

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delayFactor = (index.clamp(0, 8)) * 0.08;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index.clamp(0, 8) * 50)),
      curve: Interval(delayFactor.clamp(0.0, 0.6), 1, curve: AppDurations.curve),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, offset * (1 - value)), child: child),
      ),
    );
  }
}
