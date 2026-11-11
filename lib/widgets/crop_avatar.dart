import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_assets.dart';
import '../utils/agro_options.dart';

/// Ilustración del cultivo dentro de un círculo con tono suave.
class CropAvatar extends StatelessWidget {
  const CropAvatar({super.key, required this.cropKey, this.size = 48, this.label});

  final String cropKey;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = AppAssets.cropPhoto(cropKey);
    final asset = AgroOptions.cropAsset(cropKey);
    if (photo != null) {
      return Semantics(
        label: label,
        image: true,
        child: ClipOval(
          child: Image.asset(photo, width: size, height: size, fit: BoxFit.cover, excludeFromSemantics: true),
        ),
      );
    }
    return Semantics(
      label: label,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(color: scheme.secondaryContainer.withValues(alpha: 0.7), shape: BoxShape.circle),
        child: asset == null
            ? Icon(Icons.eco_rounded, color: scheme.primary, size: size * 0.5)
            : SvgPicture.asset(asset, excludeFromSemantics: true),
      ),
    );
  }
}
