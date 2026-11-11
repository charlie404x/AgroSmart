import 'package:flutter/material.dart';

/// Escala de espaciado (múltiplos de 4).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Radios de borde coherentes con [AppTheme].
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

/// Duraciones y curvas estándar para animaciones ligeras.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;
}

/// Puntos de quiebre para adaptar la interfaz a tablet, web y escritorio.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 840;
  static const double contentMaxWidth = 720;
  static const double formMaxWidth = 460;

  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < compact;
}

/// Devuelve true si el usuario pidió reducir animaciones en su sistema.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
