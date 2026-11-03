import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// App colours
abstract final class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const primaryDeep = Color(0xFF4834D4);
  static const primaryLight = Color(0xFFA29BFE);
  static const success = Color(0xFF00B894);
  static const danger = Color(0xFFFF5E62);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7F6CF7), primaryDeep],
  );
}

abstract final class AppRadii {
  static const field = 16.0;
  static const tile = 20.0;
  static const card = 22.0;
  static const sheet = 28.0;
}

// Light and dark themes
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: dark ? AppColors.primaryLight : AppColors.primary,
          onPrimary: dark ? const Color(0xFF1B1446) : Colors.white,
          surface: dark ? const Color(0xFF0D0F1C) : const Color(0xFFF5F6FB),
          onSurface: dark ? const Color(0xFFEDEEF7) : const Color(0xFF14162B),
          onSurfaceVariant: dark
              ? const Color(0xFF9A9DB8)
              : const Color(0xFF6B6F8A),
          surfaceContainerLow: dark ? const Color(0xFF14172A) : Colors.white,
          surfaceContainer: dark ? const Color(0xFF181B30) : Colors.white,
          surfaceContainerHigh: dark
              ? const Color(0xFF20243C)
              : const Color(0xFFECEEF6),
          outlineVariant: dark
              ? const Color(0xFF2A2E48)
              : const Color(0xFFE1E3EE),
          error: AppColors.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: kIsWeb
          ? InkRipple.splashFactory
          : InkSparkle.splashFactory,
    );
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    OutlineInputBorder border([Color? color, double width = 1.6]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: color == null
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontSize: 17,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(scheme.primary),
        errorBorder: border(AppColors.danger.withValues(alpha: 0.7), 1.2),
        focusedErrorBorder: border(AppColors.danger),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.error)
                ? AppColors.danger
                : scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
        helperStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorStyle: const TextStyle(color: AppColors.danger),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFF262A45)
            : const Color(0xFF1C1F36),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
