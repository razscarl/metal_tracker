// lib/core/theme/design_tokens.dart
//
// Resolved design token snapshot for the active theme.
// Loaded once at startup via designTokensProvider; invalidated on theme switch.
// All UI code should reference tokens through this class, never raw AppColors.

import 'package:flutter/material.dart';

class DesignTokens {
  final Map<String, String> _values; // token_name → resolved primitive value
  final Map<String, String> _types;  // token_name → token_type

  const DesignTokens(this._values, this._types);

  // ── Typed accessors ───────────────────────────────────────────────────────

  Color color(String tokenName) {
    final hex = _resolve(tokenName, 'color');
    return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
  }

  double spacing(String tokenName) =>
      double.parse(_resolve(tokenName, 'spacing'));

  double radius(String tokenName) =>
      double.parse(_resolve(tokenName, 'radius'));

  double fontSize(String tokenName) =>
      double.parse(_resolve(tokenName, 'font_size'));

  FontWeight fontWeight(String tokenName) {
    final w = int.parse(_resolve(tokenName, 'font_weight'));
    return FontWeight.values[(w ~/ 100) - 1];
  }

  String fontFamily(String tokenName) =>
      _resolve(tokenName, 'font_family');

  double opacity(String tokenName) =>
      double.parse(_resolve(tokenName, 'opacity'));

  Duration duration(String tokenName) =>
      Duration(milliseconds: int.parse(_resolve(tokenName, 'duration_ms')));

  // ── Fallback-safe accessor (returns null if token not found) ──────────────

  Color? colorOrNull(String tokenName) {
    final hex = _values[tokenName];
    if (hex == null) return null;
    return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  String _resolve(String tokenName, String expectedType) {
    final value = _values[tokenName];
    assert(value != null, 'Design token "$tokenName" not found');
    assert(
      _types[tokenName] == expectedType,
      'Token "$tokenName" is type "${_types[tokenName]}", not "$expectedType"',
    );
    return value!;
  }

  // ── Factory: build from raw Supabase rows ─────────────────────────────────
  //
  // Expects a list of maps, each with:
  //   token_name, token_type, tier, value, ref_value (primitive value for semantics)

  factory DesignTokens.fromRows(List<Map<String, dynamic>> rows) {
    final values = <String, String>{};
    final types  = <String, String>{};

    for (final row in rows) {
      final name  = row['token_name'] as String;
      final type  = row['token_type'] as String;
      final value = (row['resolved_value'] as String?) ?? '';
      values[name] = value;
      types[name]  = type;
    }

    return DesignTokens(values, types);
  }

  // ── Empty fallback (used while loading) ───────────────────────────────────

  static const empty = DesignTokens({}, {});
}
