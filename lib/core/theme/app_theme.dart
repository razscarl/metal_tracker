// lib/core/theme/app_theme.dart
//
// BRIDGE NOTICE: AppColors constants are legacy. New code must use:
//   • Theme.of(context).colorScheme.X  — for structural colours
//   • Theme.of(context).extension<AppColorExtension>()!.X  — for fixed domain colours
//   • Theme.of(context).textTheme.X  — for text styles
// AppColors will be removed once all screens are migrated.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_extension.dart';

// ─── Brand seed ───────────────────────────────────────────────────────────────
// Royal Indigo — the single source for all generated theme colours.
// Material 3 derives the full tonal palette from this one value.
const _kSeed = Color(0xFF5B5BD6);

// ─── AppTheme ─────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _kSeed,
      brightness: brightness,
    );

    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3:  true,
      colorScheme:   scheme,
      textTheme:     textTheme,
      extensions:    const [AppColorExtension.fixed],

      // ── Scaffold ────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: scheme.surface,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  scheme.surfaceContainer,
        foregroundColor:  scheme.onSurface,
        elevation:        0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          fontSize:   17,
          fontWeight: FontWeight.w600,
          color:      scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.primary),
        actionsIconTheme: IconThemeData(color: scheme.primary),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     scheme.surfaceContainerLow,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation:       1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize:   14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Filled Button ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize:   14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.inter(
            fontSize:   13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Icon Button ─────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),

      // ── Input / TextField ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle:   TextStyle(color: scheme.onSurfaceVariant),
        hintStyle:    TextStyle(color: scheme.onSurfaceVariant),
        errorStyle:   TextStyle(color: scheme.error, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Chip ────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:    scheme.surfaceContainerHighest,
        selectedColor:      scheme.primaryContainer,
        labelStyle: GoogleFonts.inter(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Tab bar ─────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:         scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor:     scheme.primary,
        labelStyle:   GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        dividerColor: scheme.outlineVariant,
      ),

      // ── Bottom sheet ────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        showDragHandle:  true,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize:   18,
          fontWeight: FontWeight.w600,
          color:      scheme.onSurface,
        ),
      ),

      // ── Progress indicator ──────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:            scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      // ── Switch ──────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.transparent
                : scheme.outline),
        thumbIcon: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? const Icon(Icons.check, size: 14)
                : null),
      ),

      // ── Checkbox ────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: scheme.outline),
      ),

      // ── Radio ───────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant),
      ),

      // ── Slider ──────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor:   scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor:         scheme.primary,
        overlayColor:       scheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: TextStyle(color: scheme.onPrimary),
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     scheme.outlineVariant,
        thickness: 1,
        space:     1,
      ),

      // ── List tile ───────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        iconColor:     scheme.primary,
        textColor:     scheme.onSurface,
        subtitleTextStyle: TextStyle(
          color:    scheme.onSurfaceVariant,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Snack bar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor:  scheme.inversePrimary,
        behavior:         SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Drawer ──────────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
        ),
      ),

      // ── Tooltip ─────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:        scheme.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),
    );
  }
}

// ─── AppColors — LEGACY BRIDGE ────────────────────────────────────────────────
// Do not add new constants here. Do not use in new code.
// Migrate usages to Theme.of(context).colorScheme or AppColorExtension.

class AppColors {
  AppColors._();

  // Metal types → use AppColorExtension.metalGold / .metalSilver / .metalPlatinum
  static const primaryGold      = Color(0xFFD4AF37);
  static const primaryGoldLight = Color(0xFFE8D090);
  static const primaryGoldDark  = Color(0xFFA8892A);
  static const secondarySilver  = Color(0xFFC0C0C0);
  static const accentPlatinum   = Color(0xFF00D4FF);

  // Backgrounds → use Theme.of(context).colorScheme.surface / .surfaceContainer
  static const backgroundDark  = Color(0xFF1A1A1A);
  static const backgroundCard  = Color(0xFF2A2A2A);
  static const backgroundLight = Color(0xFFF5F5F5);

  // Text → use Theme.of(context).colorScheme.onSurface / .onSurfaceVariant
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textDark      = Color(0xFF1A1A1A);

  // Status → use Theme.of(context).colorScheme.error for errors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error   = Color(0xFFF44336);

  // Signals → use AppColorExtension.signalGain / .signalLoss
  static const gainGreen = Color(0xFF00C853);
  static const lossRed   = Color(0xFFFF1744);

  // Price → use AppColorExtension.priceBuyback
  static const priceBuyback = Color(0xFF5B9BD5);
}
