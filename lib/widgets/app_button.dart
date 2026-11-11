import 'package:flutter/material.dart';

import '../utils/constants.dart';

enum AppButtonVariant { primary, secondary, text }

/// Botón estándar con estado de carga y microinteracción al presionar.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final onPressed = enabled ? widget.onPressed : null;
    final color = widget.variant == AppButtonVariant.primary
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;

    final Widget content = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: widget.isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[Icon(widget.icon, size: 20), const SizedBox(width: AppSpacing.sm)],
                Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final Widget button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(onPressed: onPressed, child: content),
      AppButtonVariant.secondary => OutlinedButton(onPressed: onPressed, child: content),
      AppButtonVariant.text => TextButton(onPressed: onPressed, child: content),
    };

    return Semantics(
      button: true,
      label: widget.isLoading ? '${widget.label}, cargando' : null,
      child: Listener(
        onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed && !reduceMotion(context) ? 0.97 : 1,
          duration: AppDurations.fast,
          child: widget.expand ? SizedBox(width: double.infinity, child: button) : button,
        ),
      ),
    );
  }
}
