import 'package:flutter/material.dart';

import 'package:bugpilot_ai/constants/app_dimensions.dart';

abstract final class AppTheme {
  static const String uiFontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrains Mono';

  static const Color primary = Color(0xFF4648D4);
  static const Color primaryContainer = Color(0xFF6063EE);
  static const Color surfaceTint = Color(0xFF494BD6);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color border = Color(0xFFC7C4D7);
  static const Color outline = Color(0xFF767586);
  static const Color textPrimary = Color(0xFF191C1D);
  static const Color textSecondary = Color(0xFF464554);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color secondaryContainer = Color(0xFFD6E0F1);
  static const Color onSecondaryContainer = Color(0xFF596372);
  static const Color technicalDarkSurface = Color(0xFF111827);

  static const Color darkBackground = Color(0xFF111318);
  static const Color darkSurface = Color(0xFF1A1C22);
  static const Color darkSurfaceMuted = Color(0xFF22252D);
  static const Color darkSurfaceContainer = Color(0xFF2A2D37);
  static const Color darkBorder = Color(0xFF3B4050);
  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFC7CAD6);

  static ThemeData get light {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      surfaceColor: surface,
      surfaceLowColor: surfaceLow,
      mutedSurfaceColor: surfaceContainerHighest,
      borderColor: border,
      textPrimaryColor: textPrimary,
      textSecondaryColor: textSecondary,
      errorColor: error,
      errorContainerColor: errorContainer,
      secondaryContainerColor: secondaryContainer,
    );
  }

  static ThemeData get dark {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      surfaceColor: darkSurface,
      surfaceLowColor: darkSurfaceMuted,
      mutedSurfaceColor: darkSurfaceMuted,
      borderColor: darkBorder,
      textPrimaryColor: darkTextPrimary,
      textSecondaryColor: darkTextSecondary,
      errorColor: const Color(0xFFFFB4AB),
      errorContainerColor: const Color(0xFF690005),
      secondaryContainerColor: const Color(0xFF26364F),
    );
  }

  static Color textPrimaryFor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color textSecondaryFor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color surfaceFor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color mutedSurfaceFor(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  static Color borderFor(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color surfaceColor,
    required Color surfaceLowColor,
    required Color mutedSurfaceColor,
    required Color borderColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color errorColor,
    required Color errorContainerColor,
    required Color secondaryContainerColor,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: isLight ? primaryContainer : const Color(0xFF3537A8),
      onPrimaryContainer: isLight ? const Color(0xFFFFFBFF) : Colors.white,
      secondary: isLight ? const Color(0xFF555F6D) : const Color(0xFFB9C7E2),
      onSecondary: isLight ? Colors.white : const Color(0xFF233047),
      secondaryContainer: secondaryContainerColor,
      onSecondaryContainer: isLight ? onSecondaryContainer : darkTextPrimary,
      tertiary: const Color(0xFF555C6E),
      onTertiary: Colors.white,
      tertiaryContainer: isLight
          ? const Color(0xFF6E7487)
          : const Color(0xFF553D75),
      onTertiaryContainer: isLight ? const Color(0xFFFEFCFF) : darkTextPrimary,
      error: errorColor,
      onError: isLight ? Colors.white : const Color(0xFF690005),
      errorContainer: errorContainerColor,
      onErrorContainer: isLight ? onErrorContainer : errorContainer,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
      surfaceDim: isLight ? const Color(0xFFD9DADB) : const Color(0xFF15171D),
      surfaceBright: isLight ? background : darkSurfaceContainer,
      surfaceContainerLowest: isLight ? surface : const Color(0xFF0D0F14),
      surfaceContainerLow: surfaceLowColor,
      surfaceContainer: isLight ? surfaceContainer : darkSurfaceContainer,
      surfaceContainerHighest: mutedSurfaceColor,
      onSurfaceVariant: textSecondaryColor,
      outline: outline,
      outlineVariant: borderColor,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isLight
          ? const Color(0xFF2E3132)
          : const Color(0xFFE1E3E6),
      onInverseSurface: isLight ? Colors.white : const Color(0xFF191C1D),
      inversePrimary: const Color(0xFFC0C1FF),
      surfaceTint: surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      textTheme: _textTheme(textPrimaryColor, textSecondaryColor),
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffoldBackgroundColor,
        foregroundColor: textPrimaryColor,
        titleTextStyle: _textTheme(
          textPrimaryColor,
          textSecondaryColor,
        ).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLowColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingLarge,
          vertical: AppDimensions.spacingLarge,
        ),
        hintStyle: TextStyle(
          color: textSecondaryColor.withAlpha(180),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        border: _inputBorder(borderColor),
        enabledBorder: _inputBorder(borderColor),
        focusedBorder: _inputBorder(primary, width: 1.6),
        errorBorder: _inputBorder(errorColor),
        focusedErrorBorder: _inputBorder(errorColor, width: 1.6),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: AppDimensions.spacingLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: mutedSurfaceColor,
          disabledForegroundColor: textSecondaryColor,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLarge,
            vertical: AppDimensions.spacingMedium,
          ),
          textStyle: const TextStyle(
            fontFamily: uiFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSegmented),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: BorderSide(color: borderColor),
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingLarge,
            vertical: AppDimensions.spacingMedium,
          ),
          textStyle: const TextStyle(
            fontFamily: uiFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: uiFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondaryColor,
          minimumSize: const Size.square(44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: borderColor,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mutedSurfaceColor,
        selectedColor: primary.withAlpha(isLight ? 28 : 60),
        disabledColor: mutedSurfaceColor,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        labelStyle: TextStyle(
          color: textSecondaryColor,
          fontFamily: uiFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isLight ? Colors.white : const Color(0xFFCDD1DC);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return mutedSurfaceColor;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return borderColor;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primary;
            }
            return surfaceLowColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return textSecondaryColor;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: borderColor)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: uiFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 38 / 30,
        letterSpacing: 0,
      ),
      headlineLarge: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        color: secondaryText,
        fontFamily: uiFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        color: secondaryText,
        fontFamily: uiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        color: secondaryText,
        fontFamily: uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        color: primaryText,
        fontFamily: uiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        color: secondaryText,
        fontFamily: uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.6,
      ),
      labelSmall: TextStyle(
        color: secondaryText,
        fontFamily: uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.6,
      ),
    );
  }
}
