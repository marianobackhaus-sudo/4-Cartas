import 'package:flutter/animation.dart';

/// Motion system — based on emil-design-eng standards and animate skill patterns.
///
/// Principles (from emil-design-eng):
/// - Short is better than long (UI animations = 100–300ms, never >500ms except reveals).
/// - Out-curves for entries (fast start, gentle end); in-out for movement.
/// - Interruptible — never block the user.
/// - Easing > linear. Linear feels mechanical.
class AppDurations {
  AppDurations._();

  /// 120ms — micro feedback (press/ripple). Feels instantaneous.
  static const Duration micro = Duration(milliseconds: 120);

  /// 200ms — default UI transitions (fade, button state, tooltip).
  static const Duration fast = Duration(milliseconds: 200);

  /// 320ms — container moves, slide-ins, modal enters.
  static const Duration base = Duration(milliseconds: 320);

  /// 480ms — reveal animations (score, winner), card flip finale.
  static const Duration slow = Duration(milliseconds: 480);

  /// 640ms — hero moments: match-winner reveal, deck dealing overall.
  static const Duration emphasis = Duration(milliseconds: 640);

  /// Per-card stagger when dealing. Keep small so total dealing ≤1s.
  static const Duration dealStagger = Duration(milliseconds: 80);
}

class AppCurves {
  AppCurves._();

  /// Material standard — most UI.
  static const Curve standard = Curves.easeOutCubic;

  /// Entrances (fade-in, slide-in).
  static const Curve enter = Curves.easeOutCubic;

  /// Exits (fade-out, dismiss).
  static const Curve exit = Curves.easeInCubic;

  /// Moves between two points.
  static const Curve emphasized = Curves.easeInOutCubic;

  /// Slight overshoot for playful interactions (card flip, success beat).
  static const Curve spring = Curves.easeOutBack;

  /// Decelerate hard — deck shuffle end, snap to slot.
  static const Curve decelerate = Curves.decelerate;
}

/// Named presets so widgets request intent, not numbers.
/// Maps to the 8 animation patterns from the `animate` skill, adapted to Flutter.
class AppMotion {
  AppMotion._();

  /// Card flip — 3D rotation around Y axis. Use 2 halves: out-curve in, out-curve out.
  /// Total ≤500ms. Spring curve adds "slap" feel.
  static const Duration cardFlip = AppDurations.slow;
  static const Curve cardFlipCurve = AppCurves.spring;

  /// Card hover/press feedback — micro scale 0.97 + elevation bump.
  static const Duration pressFeedback = AppDurations.micro;
  static const Curve pressCurve = AppCurves.standard;

  /// Deal card from deck to slot — staggered, snaps at end.
  static const Duration dealOne = AppDurations.base;
  static const Curve dealCurve = AppCurves.decelerate;

  /// Toast / snackbar enter.
  static const Duration toastEnter = AppDurations.fast;
  static const Duration toastExit = AppDurations.fast;
  static const Curve toastCurve = AppCurves.standard;

  /// Turn banner slide + pulse.
  static const Duration turnBanner = AppDurations.base;
  static const Curve turnBannerCurve = AppCurves.emphasized;

  /// Score reveal (staggered digit count-up).
  static const Duration scoreReveal = AppDurations.slow;
  static const Curve scoreRevealCurve = AppCurves.emphasized;

  /// Route transitions.
  static const Duration routeTransition = AppDurations.base;
  static const Curve routeCurve = AppCurves.standard;

  /// Mirror button pulse (indicates open window).
  static const Duration mirrorPulse = Duration(milliseconds: 900);
  static const Curve mirrorPulseCurve = Curves.easeInOut;
}

/// Press-feedback scale values — tactile feedback per emil-design-eng.
/// Never scale below 0.95 — anything more looks broken.
class AppPressScale {
  AppPressScale._();
  static const double card = 0.97;
  static const double button = 0.96;
  static const double icon = 0.92;
}
