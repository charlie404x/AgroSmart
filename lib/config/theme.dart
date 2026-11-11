import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Colores semánticos adicionales que no forman parte de [ColorScheme].
@immutable
class AgroColors extends ThemeExtension<AgroColors> {
  const AgroColors({
    required this.success,
    required this.onSuccessContainer,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.earth,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Tono tierra para precios e ingresos.
  final Color earth;

  /// Extremos del degradado sutil de las tarjetas destacadas.
  final Color heroStart;
  final Color heroEnd;

  static const light = AgroColors(
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFDDF2D8),
    onSuccessContainer: Color(0xFF0E3B12),
    warning: Color(0xFFB26A00),
    warningContainer: Color(0xFFFFEBC7),
    onWarningContainer: Color(0xFF4A2C00),
    info: Color(0xFF0B6E99),
    infoContainer: Color(0xFFD7EEF8),
    onInfoContainer: Color(0xFF00344A),
    earth: Color(0xFF8A5A1C),
    heroStart: Color(0xFF1F6B3A),
    heroEnd: Color(0xFF2F8A4E),
  );

  static const dark = AgroColors(
    success: Color(0xFF8FD18A),
    successContainer: Color(0xFF1D3A1E),
    onSuccessContainer: Color(0xFFCDEFC6),
    warning: Color(0xFFF2C14E),
    warningContainer: Color(0xFF3D2E0A),
    onWarningContainer: Color(0xFFFFE3A6),
    info: Color(0xFF7CC8EA),
    infoContainer: Color(0xFF0E3445),
    onInfoContainer: Color(0xFFCDEBF8),
    earth: Color(0xFFE2B377),
    heroStart: Color(0xFF173F25),
    heroEnd: Color(0xFF225A34),
  );

  @override
  AgroColors copyWith() => this;

  @override
  AgroColors lerp(ThemeExtension<AgroColors>? other, double t) {
    if (other is! AgroColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AgroColors(
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      earth: l(earth, other.earth),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
    );
  }
}

extension AgroThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AgroColors get agro => Theme.of(this).extension<AgroColors>()!;
}

/// Sistema de diseño de AgroSMART Perú (Material 3).
class AppTheme {
  AppTheme._();

  /// Verde agrícola de marca.
  static const Color brandGreen = Color(0xFF2E7D32);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: brandGreen, brightness: brightness).copyWith(
      primary: isDark ? const Color(0xFF8FD18A) : const Color(0xFF1F6B3A),
      surface: isDark ? const Color(0xFF0F1A12) : const Color(0xFFF7FAF5),
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
    final text = _textTheme(base.textTheme, scheme);
    final radiusMd = BorderRadius.circular(AppRadius.md);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: [isDark ? AgroColors.dark : AgroColors.light],
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: text.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
        border: OutlineInputBorder(borderRadius: radiusMd),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused) ? scheme.primary : scheme.onSurfaceVariant,
        ),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
        indicatorColor: scheme.primaryContainer,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      sliderTheme: SliderThemeData(trackHeight: 6, inactiveTrackColor: scheme.primaryContainer),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? tune(TextStyle? s, {FontWeight? weight, double? spacing, double? height}) =>
        s?.copyWith(fontWeight: weight, letterSpacing: spacing, height: height);
    return base
        .copyWith(
          displaySmall: tune(base.displaySmall, weight: FontWeight.w700, spacing: -0.5),
          headlineMedium: tune(base.headlineMedium, weight: FontWeight.w700, spacing: -0.4),
          headlineSmall: tune(base.headlineSmall, weight: FontWeight.w700, spacing: -0.2),
          titleLarge: tune(base.titleLarge, weight: FontWeight.w700, spacing: -0.1),
          titleMedium: tune(base.titleMedium, weight: FontWeight.w600),
          titleSmall: tune(base.titleSmall, weight: FontWeight.w600),
          bodyLarge: tune(base.bodyLarge, height: 1.45),
          bodyMedium: tune(base.bodyMedium, height: 1.45),
          labelLarge: tune(base.labelLarge, weight: FontWeight.w600),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
