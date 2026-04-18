import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Type scale — based on ui-ux-pro-max typography guidance + Material 3.
///
/// Decisions:
/// - Single system font stack (Roboto on Android, SF on iOS via `inherit`).
///   Keeps binary small and startup fast — hackathon priority.
/// - Display/headline use heavier weight (700) for game moments.
/// - Body 15/22 hits optimal mobile reading per ui-ux-pro-max guideline.
/// - Numbers for scores use tabular figures via FontFeature.tabularFigures.
class AppText {
  AppText._();

  static const String _family = 'Roboto';

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textMuted,
  );

  /// Big gold CTA label — room code, winner announce.
  static const TextStyle hero = TextStyle(
    fontFamily: _family,
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: AppColors.primary,
  );

  /// Tabular numerics for scores.
  static const TextStyle scoreNumeric = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Card rank face (A, 2..10, J, Q, K). Very large, heavy.
  static const TextStyle cardRank = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 1.0,
    fontWeight: FontWeight.w800,
    color: AppColors.cardInkBlack,
  );

  /// Small corner rank on card.
  static const TextStyle cardCorner = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.0,
    fontWeight: FontWeight.w700,
    color: AppColors.cardInkBlack,
  );
}
