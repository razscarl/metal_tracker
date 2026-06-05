// lib/core/theme/app_color_extension.dart
//
// Fixed domain colours — identical in every theme (light, dark, accessibility).
// These represent real-world objects and signals; they must never shift with
// the theme. Access via Theme.of(context).extension<AppColorExtension>()!
//
// See CLAUDE.md → Colour and Design Token Rules for reservation policy.

import 'package:flutter/material.dart';

@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.metalGold,
    required this.metalSilver,
    required this.metalPlatinum,
    required this.signalGain,
    required this.signalLoss,
    required this.signalWarning,
    required this.priceBuyback,
  });

  // ── Metal type colours ────────────────────────────────────────────────────
  final Color metalGold;       // Gold metal type label, icon, chart
  final Color metalSilver;     // Silver metal type label, icon, chart
  final Color metalPlatinum;   // Platinum metal type label, icon, chart

  // ── Financial signals ─────────────────────────────────────────────────────
  final Color signalGain;      // Portfolio gain / positive outcome ONLY
  final Color signalLoss;      // Portfolio loss / negative outcome ONLY
  final Color signalWarning;   // System warning status ONLY

  // ── Price display ─────────────────────────────────────────────────────────
  final Color priceBuyback;    // Buyback / bid price display ONLY

  // ── Singleton — use this everywhere ──────────────────────────────────────
  static const fixed = AppColorExtension(
    metalGold:     Color(0xFFD4AF37),
    metalSilver:   Color(0xFFC0C0C0),
    metalPlatinum: Color(0xFF00D4FF),
    signalGain:    Color(0xFF00C853),
    signalLoss:    Color(0xFFFF1744),
    signalWarning: Color(0xFFFFC107),
    priceBuyback:  Color(0xFF5B9BD5),
  );

  // ── ThemeExtension boilerplate ────────────────────────────────────────────

  @override
  AppColorExtension copyWith({
    Color? metalGold,
    Color? metalSilver,
    Color? metalPlatinum,
    Color? signalGain,
    Color? signalLoss,
    Color? signalWarning,
    Color? priceBuyback,
  }) =>
      AppColorExtension(
        metalGold:     metalGold     ?? this.metalGold,
        metalSilver:   metalSilver   ?? this.metalSilver,
        metalPlatinum: metalPlatinum ?? this.metalPlatinum,
        signalGain:    signalGain    ?? this.signalGain,
        signalLoss:    signalLoss    ?? this.signalLoss,
        signalWarning: signalWarning ?? this.signalWarning,
        priceBuyback:  priceBuyback  ?? this.priceBuyback,
      );

  // These colours are fixed across all themes so lerp always returns fixed.
  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other is! AppColorExtension) return this;
    return AppColorExtension(
      metalGold:     Color.lerp(metalGold,     other.metalGold,     t)!,
      metalSilver:   Color.lerp(metalSilver,   other.metalSilver,   t)!,
      metalPlatinum: Color.lerp(metalPlatinum, other.metalPlatinum, t)!,
      signalGain:    Color.lerp(signalGain,    other.signalGain,    t)!,
      signalLoss:    Color.lerp(signalLoss,    other.signalLoss,    t)!,
      signalWarning: Color.lerp(signalWarning, other.signalWarning, t)!,
      priceBuyback:  Color.lerp(priceBuyback,  other.priceBuyback,  t)!,
    );
  }
}
