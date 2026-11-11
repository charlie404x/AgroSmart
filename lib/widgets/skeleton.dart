import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Bloque de carga con brillo animado (skeleton loader).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
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
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerLow;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + 3 * t, 0),
                end: Alignment(-0.5 + 3 * t, 0),
                colors: [base, highlight, base],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lista de tarjetas esqueleto para pantallas en carga.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 4, this.height = 104});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando',
    child: Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Skeleton(height: height, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
      ],
    ),
  );
}
