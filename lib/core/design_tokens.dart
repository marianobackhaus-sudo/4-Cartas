import 'package:flutter/material.dart';

/// Design tokens — 3-layer architecture (primitive → semantic → component).
/// Inspired by ckm-design-system tokenization + ui-ux-pro-max palette guidance.
///
/// Primitive = raw hex values. Semantic = roles (surface/primary/danger).
/// Component-level choices live in theme.dart or widget files.
class AppColors {
  AppColors._();

  // ── Primitives ───────────────────────────────────────────────────────────
  static const Color _midnight950 = Color(0xFF0A0E17); // deepest bg
  static const Color _midnight900 = Color(0xFF111826); // scaffold bg
  static const Color _midnight800 = Color(0xFF1A2236); // surface
  static const Color _midnight700 = Color(0xFF27304A); // surface elevated
  static const Color _midnight600 = Color(0xFF3A455E); // border

  static const Color _felt900 = Color(0xFF0E2A22); // table green deep
  static const Color _felt800 = Color(0xFF134233); // table green surface

  static const Color _gold500 = Color(0xFFF5B642); // primary accent
  static const Color _gold400 = Color(0xFFFFCB66);
  static const Color _gold600 = Color(0xFFD4962A);

  static const Color _electric500 = Color(0xFF4DA3FF); // your turn
  static const Color _electric400 = Color(0xFF7FBEFF);

  static const Color _success500 = Color(0xFF34D399);
  static const Color _danger500 = Color(0xFFF04B4B);
  static const Color _warning500 = Color(0xFFF59E0B);

  static const Color _paper50 = Color(0xFFF7F5EF); // card face
  static const Color _paper100 = Color(0xFFE8E3D5);

  static const Color _ink900 = Color(0xFF1A1A1A); // card text
  static const Color _ink600 = Color(0xFF555555);

  static const Color _joker500 = Color(0xFFA78BFA); // joker accent

  // Suit semantics (cards).
  static const Color _suitRed = Color(0xFFD63D3D);
  static const Color _suitBlack = Color(0xFF1F2430);

  // ── Semantic — background / surface ──────────────────────────────────────
  static const Color bgDeepest = _midnight950;
  static const Color bgBase = _midnight900;
  static const Color bgTable = _felt900;
  static const Color bgTableElevated = _felt800;
  static const Color surface = _midnight800;
  static const Color surfaceElevated = _midnight700;
  static const Color surfaceOverlay = Color(0xDD0A0E17); // modal scrim
  static const Color border = _midnight600;
  static const Color divider = Color(0x1FFFFFFF);

  // ── Semantic — text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFB5BACB);
  static const Color textMuted = Color(0xFF7A8095);
  static const Color textInverse = _ink900;
  static const Color textOnLight = _ink600; // secondary text on card face

  // ── Semantic — action / accent ───────────────────────────────────────────
  static const Color primary = _gold500;
  static const Color primaryHover = _gold400;
  static const Color primaryPressed = _gold600;
  static const Color onPrimary = _ink900;

  static const Color accent = _electric500;
  static const Color accentSoft = _electric400;

  // ── Semantic — state ─────────────────────────────────────────────────────
  static const Color success = _success500;
  static const Color danger = _danger500;
  static const Color warning = _warning500;

  // ── Component — cards ────────────────────────────────────────────────────
  static const Color cardFace = _paper50;
  static const Color cardFaceEdge = _paper100;
  static const Color cardBack = _midnight700;
  static const Color cardBackPattern = _gold600;
  static const Color cardInkBlack = _suitBlack;
  static const Color cardInkRed = _suitRed;
  static const Color cardInkJoker = _joker500;

  // ── Component — game state cues ──────────────────────────────────────────
  static const Color turnGlow = _electric500;
  static const Color cutGlow = _danger500;
  static const Color winGlow = _gold500;
}

/// 4-pt base spacing scale. Touch-target min 48 per ui-ux-pro-max guideline.
class AppSpacing {
  AppSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 40;
  static const double xl4 = 48;
  static const double xl5 = 64;

  static const double touchTarget = 48;
}

class AppRadius {
  AppRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double card = 14; // playing card corner
  static const double pill = 999;
}

class AppElevation {
  AppElevation._();
  static const double none = 0;
  static const double raised = 2;
  static const double floating = 6;
  static const double overlay = 12;
  static const double modal = 20;
}

/// Standard card aspect + sizing. 2.5:3.5 matches classic poker cards.
class AppCardDims {
  AppCardDims._();
  static const double aspectRatio = 2.5 / 3.5;
  static const double minWidth = 56;
  static const double defaultWidth = 72;
  static const double featuredWidth = 120; // drawn card preview
}
