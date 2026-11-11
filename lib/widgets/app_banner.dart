import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/constants.dart';

enum BannerTone { info, success, warning, error }

/// Aviso en línea (información, éxito, advertencia o error).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.info,
    this.title,
    this.actionLabel,
    this.onAction,
    this.onClose,
  });

  final String message;
  final String? title;
  final BannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final agro = context.agro;
    final scheme = context.colors;
    final (Color bg, Color fg, IconData icon) = switch (tone) {
      BannerTone.info => (agro.infoContainer, agro.onInfoContainer, Icons.info_outline_rounded),
      BannerTone.success => (agro.successContainer, agro.onSuccessContainer, Icons.check_circle_outline_rounded),
      BannerTone.warning => (agro.warningContainer, agro.onWarningContainer, Icons.warning_amber_rounded),
      BannerTone.error => (scheme.errorContainer, scheme.onErrorContainer, Icons.error_outline_rounded),
    };

    return Semantics(
      liveRegion: tone == BannerTone.error,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm + 4, AppSpacing.sm, AppSpacing.sm + 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) Text(title!, style: context.text.titleSmall?.copyWith(color: fg)),
                  Text(message, style: context.text.bodyMedium?.copyWith(color: fg)),
                  if (actionLabel != null && onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: fg,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ),
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Cerrar aviso',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, color: fg, size: 20),
                onPressed: onClose,
              )
            else
              const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
