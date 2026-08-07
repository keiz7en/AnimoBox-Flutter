import 'package:flutter/material.dart';

class AccentColors {
  final String name;
  final Color main;
  final Color strong;
  final Color gradientStart;
  final Color gradientEnd;
  final Color line;

  const AccentColors({
    required this.name,
    required this.main,
    required this.strong,
    required this.gradientStart,
    required this.gradientEnd,
    required this.line,
  });
}

const List<AccentColors> accentPalette = [
  AccentColors(name: 'Gold', main: Color(0xFFd7a35a), strong: Color(0xFFefbf7a), gradientStart: Color(0xF2d7a35a), gradientEnd: Color(0xf0c28e41), line: Color(0x38e5aa56)),
  AccentColors(name: 'Blue', main: Color(0xFF5a9fd7), strong: Color(0xFF7abfef), gradientStart: Color(0xF25a9fd7), gradientEnd: Color(0xf0418ec2), line: Color(0x3856a5e5)),
  AccentColors(name: 'Red', main: Color(0xFFd75a5a), strong: Color(0xFFef7a7a), gradientStart: Color(0xF2d75a5a), gradientEnd: Color(0xf0c24141), line: Color(0x38e55656)),
  AccentColors(name: 'Purple', main: Color(0xFF9f5ad7), strong: Color(0xFFbf7aef), gradientStart: Color(0xF29f5ad7), gradientEnd: Color(0xf08e41c2), line: Color(0x38aa56e5)),
  AccentColors(name: 'Green', main: Color(0xFF5ad77a), strong: Color(0xFF7aef9f), gradientStart: Color(0xF25ad77a), gradientEnd: Color(0xf041c266), line: Color(0x3856e57a)),
  AccentColors(name: 'Pink', main: Color(0xFFd75aaf), strong: Color(0xFFef7acf), gradientStart: Color(0xF2d75aaf), gradientEnd: Color(0xf0c2419a), line: Color(0x38e556bf)),
  AccentColors(name: 'Cyan', main: Color(0xFF5ad7d7), strong: Color(0xFF7aefef), gradientStart: Color(0xF25ad7d7), gradientEnd: Color(0xf041c2c2), line: Color(0x3856e5e5)),
  AccentColors(name: 'Orange', main: Color(0xFFd79f5a), strong: Color(0xFFefbf7a), gradientStart: Color(0xF2d79f5a), gradientEnd: Color(0xf0c28e41), line: Color(0x38e5aa56)),
];

class AppTheme {
  final String name;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color text;
  final Color textSoft;
  final Color textDim;
  final Color danger;
  final Color success;
  final Color lineSoft;
  final Color shadow;
  final Color overlay;
  final Color cardBorder;
  final Color chipBg;
  final Color rowDivider;

  const AppTheme({
    required this.name,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.textSoft,
    required this.textDim,
    required this.danger,
    required this.success,
    required this.lineSoft,
    required this.shadow,
    required this.overlay,
    required this.cardBorder,
    required this.chipBg,
    required this.rowDivider,
  });
}

const List<AppTheme> appThemes = [
  AppTheme(
    name: 'Dark',
    bg: Color(0xFF090a0c), surface: Color(0xFF121315), surface2: Color(0xFF16181c), surface3: Color(0xFF1d2024),
    text: Color(0xFFf3efe8), textSoft: Color(0xB3f3efe8), textDim: Color(0x6bf3efe8),
    danger: Color(0xFFc66767), success: Color(0xFF7dbd92),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD80c0d10),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
  AppTheme(
    name: 'Light',
    bg: Color(0xFFf5f5f5), surface: Color(0xFFffffff), surface2: Color(0xFFe8e8e8), surface3: Color(0xFFdcdcdc),
    text: Color(0xFF1a1a1a), textSoft: Color(0x991a1a1a), textDim: Color(0x611a1a1a),
    danger: Color(0xFFc62828), success: Color(0xFF2e7d32),
    lineSoft: Color(0x14000000), shadow: Color(0x1a000000), overlay: Color(0xD8ffffff),
    cardBorder: Color(0x10000000), chipBg: Color(0x08000000), rowDivider: Color(0x0d000000),
  ),
  AppTheme(
    name: 'Dracula',
    bg: Color(0xFF282a36), surface: Color(0xFF343746), surface2: Color(0xFF3c3e50), surface3: Color(0xFF44475a),
    text: Color(0xFFf8f8f2), textSoft: Color(0xB3f8f8f2), textDim: Color(0x6bf8f8f2),
    danger: Color(0xFFff5555), success: Color(0xFF50fa7b),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD8282a36),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
  AppTheme(
    name: 'Magenta',
    bg: Color(0xFF1a0a1a), surface: Color(0xFF241224), surface2: Color(0xFF2e1a2e), surface3: Color(0xFF3a223a),
    text: Color(0xFFf0e0f0), textSoft: Color(0xB3f0e0f0), textDim: Color(0x6bf0e0f0),
    danger: Color(0xFFe567e5), success: Color(0xFF7dbd92),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD81a0a1a),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
  AppTheme(
    name: 'Monokai',
    bg: Color(0xFF272822), surface: Color(0xFF3e3d32), surface2: Color(0xFF49483e), surface3: Color(0xFF575649),
    text: Color(0xFFf8f8f2), textSoft: Color(0xB3f8f8f2), textDim: Color(0x6bf8f8f2),
    danger: Color(0xFFf92672), success: Color(0xFFa6e22e),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD8272822),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
  AppTheme(
    name: 'Nord',
    bg: Color(0xFF2e3440), surface: Color(0xFF3b4252), surface2: Color(0xFF434c5e), surface3: Color(0xFF4c566a),
    text: Color(0xFFeceff4), textSoft: Color(0xB3eceff4), textDim: Color(0x6beceff4),
    danger: Color(0xFFbf616a), success: Color(0xFFa3be8c),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD82e3440),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
  AppTheme(
    name: 'Solarized',
    bg: Color(0xFF002b36), surface: Color(0xFF073642), surface2: Color(0xFF0a4050), surface3: Color(0xFF0d4f5e),
    text: Color(0xFFfdf6e3), textSoft: Color(0xB3fdf6e3), textDim: Color(0x6bfdf6e3),
    danger: Color(0xFFdc322f), success: Color(0xFF859900),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD8002b36),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
  AppTheme(
    name: 'One Dark',
    bg: Color(0xFF282c34), surface: Color(0xFF2c313a), surface2: Color(0xFF333842), surface3: Color(0xFF3e4450),
    text: Color(0xFFabb2bf), textSoft: Color(0xB3abb2bf), textDim: Color(0x6babb2bf),
    danger: Color(0xFFe06c75), success: Color(0xFF98c379),
    lineSoft: Color(0x14ffffff), shadow: Color(0x57000000), overlay: Color(0xD8282c34),
    cardBorder: Color(0x10ffffff), chipBg: Color(0x08ffffff), rowDivider: Color(0x0dffffff),
  ),
];

class NipahColors {
  NipahColors._();

  static AccentColors _accent = accentPalette[0];
  static AccentColors get accent => _accent;
  static Color get gold => _accent.main;
  static Color get goldStrong => _accent.strong;
  static Color get goldGradientStart => _accent.gradientStart;
  static Color get goldGradientEnd => _accent.gradientEnd;
  static Color get line => _accent.line;

  static AppTheme _theme = appThemes[0];
  static AppTheme get theme => _theme;

  static Color get bg => _theme.bg;
  static Color get surface => _theme.surface;
  static Color get surface2 => _theme.surface2;
  static Color get surface3 => _theme.surface3;
  static Color get text => _theme.text;
  static Color get textSoft => _theme.textSoft;
  static Color get textDim => _theme.textDim;
  static Color get danger => _theme.danger;
  static Color get success => _theme.success;
  static Color get lineSoft => _theme.lineSoft;
  static Color get shadow => _theme.shadow;
  static Color get overlay => _theme.overlay;
  static Color get cardBorder => _theme.cardBorder;
  static Color get chipBg => _theme.chipBg;
  static Color get rowDivider => _theme.rowDivider;

  static void setAccent(String name) {
    _accent = accentPalette.firstWhere((a) => a.name == name, orElse: () => accentPalette[0]);
  }

  static void setTheme(String name) {
    _theme = appThemes.firstWhere((t) => t.name == name, orElse: () => appThemes[0]);
  }
}

class NipahTheme {
  NipahTheme._();

  static const _fontFamily = 'Plus Jakarta Sans';
  static const _headingFamily = 'Plus Jakarta Sans';

  static TextStyle heading({
    double size = 32,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double letterSpacing = -0.05,
    double height = 0.95,
  }) {
    return TextStyle(
      fontFamily: _headingFamily,
      fontSize: size,
      fontWeight: weight,
      color: color ?? NipahColors.text,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color ?? NipahColors.textSoft,
      height: height,
    );
  }

  static TextStyle label({
    double size = 11,
    FontWeight weight = FontWeight.w800,
    Color? color,
    double letterSpacing = 0.14,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color ?? NipahColors.gold,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle posterTitle({double size = 12, Color? color}) {
    return TextStyle(fontFamily: _fontFamily, fontSize: size, fontWeight: FontWeight.w700, color: color ?? NipahColors.text);
  }

  static TextStyle posterMeta({double size = 11, Color? color}) {
    return TextStyle(fontFamily: _fontFamily, fontSize: size, color: color ?? NipahColors.textDim);
  }

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: NipahColors.surface,
    border: Border.all(color: NipahColors.accent.main.withValues(alpha: 0.18)),
    boxShadow: [
      BoxShadow(color: NipahColors.accent.main.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
    ],
  );

  static BoxDecoration get heroCardDecoration => BoxDecoration(
    color: NipahColors.surface,
    border: Border.all(color: NipahColors.accent.main.withValues(alpha: 0.25)),
    boxShadow: [
      BoxShadow(color: NipahColors.accent.main.withValues(alpha: 0.10), blurRadius: 48, offset: const Offset(0, 16)),
    ],
  );

  static BoxDecoration get sectionCardDecoration => BoxDecoration(
    border: Border.all(color: NipahColors.accent.main.withValues(alpha: 0.12)),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        NipahColors.accent.main.withValues(alpha: 0.10),
        NipahColors.text.withValues(alpha: 0.02),
        NipahColors.surface,
      ],
      stops: const [0.0, 0.22, 0.5],
    ),
  );

  static BoxDecoration get goldButtonDecoration => BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: NipahColors.accent.main.withValues(alpha: 0.36))),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [NipahColors.goldGradientStart, NipahColors.goldGradientEnd],
    ),
  );

  static BoxDecoration get ghostButtonDecoration => BoxDecoration(
    border: Border.fromBorderSide(BorderSide(color: NipahColors.lineSoft)),
    color: NipahColors.chipBg,
  );

  static BorderRadius get radius => BorderRadius.zero;
  static BorderRadius radiusAll(double r) => BorderRadius.all(Radius.circular(r));

  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animMedium = Duration(milliseconds: 220);
  static const Duration animSlow = Duration(milliseconds: 320);
}
