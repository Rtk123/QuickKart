import 'package:flutter/material.dart';

/// Brand ke woh colors jo Material ke standard `ColorScheme` roles mein
/// fit nahi hote (hero banner, paid/pending badges). Light aur dark dono
/// themes apni values deti hain, isliye koi bhi screen hardcoded color
/// use nahi karti — sab kuch theme se aata hai.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.heroBg,
    required this.heroTitle,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.badgeBg,
    required this.badgeFg,
    required this.headerBg,
    required this.headerFg,
    required this.headerMuted,
    required this.headerGradient,
    required this.addGreen,
  });

  final Color heroBg;
  final Color heroTitle;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;

  /// "12 min" delivery pill — dono themes mein solid green pill rehta hai,
  /// bas dark mode mein foreground thoda soft kar diya gaya hai.
  final Color badgeBg;
  final Color badgeFg;

  /// Top header ka gradient (JioHotstar-style violet -> magenta -> orange)
  /// aur uske upar ka text. `headerBg` sirf fallback hai.
  final Color headerBg;
  final Color headerFg;
  final Color headerMuted;
  final List<Color> headerGradient;

  /// Product card ka "ADD" button — quick-commerce apps mein hamesha green.
  final Color addGreen;

  static const light = AppPalette(
    heroBg: Color(0xFFFAECE7),
    heroTitle: Color(0xFF993C1D),
    success: Color(0xFF0F6E56),
    successBg: Color(0xFFE1F5EE),
    warning: Color(0xFF993C1D),
    warningBg: Color(0xFFFAECE7),
    badgeBg: Color(0xFF0F6E56),
    badgeFg: Colors.white,
    headerBg: Color(0xFF7B2FF7),
    headerFg: Colors.white,
    headerMuted: Color(0xFFEBDCFF),
    headerGradient: [Color(0xFF6A1FD0), Color(0xFFB4218F), Color(0xFFF2545B)],
    addGreen: Color(0xFF0C831F),
  );

  static const dark = AppPalette(
    heroBg: Color(0xFF3A2620),
    heroTitle: Color(0xFFF0B49A),
    success: Color(0xFF5FD3AE),
    successBg: Color(0xFF10362C),
    warning: Color(0xFFF0B49A),
    warningBg: Color(0xFF3A2620),
    badgeBg: Color(0xFF1B7A62),
    badgeFg: Color(0xFFEAFFF8),
    headerBg: Color(0xFF3B1470),
    headerFg: Colors.white,
    headerMuted: Color(0xFFD8C6F0),
    headerGradient: [Color(0xFF3A1078), Color(0xFF6E1656), Color(0xFF8E3038)],
    addGreen: Color(0xFF3DBF52),
  );

  /// Kisi bhi widget se: `Theme.of(context).palette`
  @override
  AppPalette copyWith({
    Color? heroBg,
    Color? heroTitle,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? badgeBg,
    Color? badgeFg,
    Color? headerBg,
    Color? headerFg,
    Color? headerMuted,
    List<Color>? headerGradient,
    Color? addGreen,
  }) {
    return AppPalette(
      heroBg: heroBg ?? this.heroBg,
      heroTitle: heroTitle ?? this.heroTitle,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      badgeBg: badgeBg ?? this.badgeBg,
      badgeFg: badgeFg ?? this.badgeFg,
      headerBg: headerBg ?? this.headerBg,
      headerFg: headerFg ?? this.headerFg,
      headerMuted: headerMuted ?? this.headerMuted,
      headerGradient: headerGradient ?? this.headerGradient,
      addGreen: addGreen ?? this.addGreen,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      heroBg: Color.lerp(heroBg, other.heroBg, t)!,
      heroTitle: Color.lerp(heroTitle, other.heroTitle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      badgeBg: Color.lerp(badgeBg, other.badgeBg, t)!,
      badgeFg: Color.lerp(badgeFg, other.badgeFg, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
      headerFg: Color.lerp(headerFg, other.headerFg, t)!,
      headerMuted: Color.lerp(headerMuted, other.headerMuted, t)!,
      // Dono themes ke gradient mein utne hi stops hain, isliye index-wise lerp.
      headerGradient: [
        for (var i = 0; i < headerGradient.length; i++)
          Color.lerp(headerGradient[i], other.headerGradient[i], t)!,
      ],
      addGreen: Color.lerp(addGreen, other.addGreen, t)!,
    );
  }
}

extension AppThemeX on ThemeData {
  AppPalette get palette => extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  const AppTheme._();

  static const brand = Color(0xFFD85A30);

  static final light = _build(
    Brightness.light,
    const ColorScheme.light(
      primary: brand,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF2C2C2A),
      onSurfaceVariant: Color(0xFF5F5E5A),
      surfaceContainerHighest: Color(0xFFFFF9F2),
      outlineVariant: Color(0xFFEAE3D8),
      error: Color(0xFFC0392B),
    ),
    scaffoldBg: const Color(0xFFFFF9F2),
    palette: AppPalette.light,
  );

  static final dark = _build(
    Brightness.dark,
    const ColorScheme.dark(
      primary: brand,
      onPrimary: Colors.white,
      surface: Color(0xFF1F1C18),
      onSurface: Color(0xFFF2EDE6),
      onSurfaceVariant: Color(0xFFB5AEA3),
      surfaceContainerHighest: Color(0xFF2A2621),
      outlineVariant: Color(0xFF3A352E),
      error: Color(0xFFFF8A80),
    ),
    scaffoldBg: const Color(0xFF141210),
    palette: AppPalette.dark,
  );

  static ThemeData _build(
    Brightness brightness,
    ColorScheme scheme, {
    required Color scaffoldBg,
    required AppPalette palette,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: 'Roboto',
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: brand,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
