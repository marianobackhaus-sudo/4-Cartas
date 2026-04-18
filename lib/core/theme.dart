import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'motion.dart';
import 'typography.dart';

/// Assembles Flutter ThemeData from design tokens.
/// Consumed by `App` in `lib/app.dart`.
class AppTheme {
  AppTheme._();

  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.onPrimary,
      error: AppColors.danger,
      onError: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    final textTheme = const TextTheme(
      displayLarge: AppText.display,
      displayMedium: AppText.display,
      headlineLarge: AppText.headline,
      headlineMedium: AppText.headline,
      titleLarge: AppText.title,
      titleMedium: AppText.titleSmall,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      labelLarge: AppText.bodyStrong,
      labelMedium: AppText.label,
      labelSmall: AppText.caption,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      canvasColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionBuilder(),
          TargetPlatform.macOS: _FadeSlidePageTransitionBuilder(),
          TargetPlatform.windows: _FadeSlidePageTransitionBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textMuted,
          textStyle: AppText.bodyStrong,
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          animationDuration: AppDurations.fast,
          elevation: AppElevation.raised,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppText.bodyStrong,
          side: const BorderSide(color: AppColors.border, width: 1),
          minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppText.bodyStrong,
          minimumSize: const Size(0, AppSpacing.touchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        labelStyle: AppText.label,
        hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppElevation.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: AppElevation.modal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: AppText.title,
        contentTextStyle: AppText.body,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppText.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
        thickness: 1,
      ),
    );
  }
}

/// Unified page transition — fade + slight vertical slide. Matches AppMotion.routeTransition.
class _FadeSlidePageTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: AppMotion.routeCurve);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
