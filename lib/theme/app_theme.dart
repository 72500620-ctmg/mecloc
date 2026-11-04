import 'package:flutter/material.dart';

/// Cores de marca (mantidas por compatibilidade).
class AppColors {
  static const forest = Color(0xFF174D43);
  static const leaf = Color(0xFFB5D93B);
  static const ink = Color(0xFF0B0B0C);
  static const paper = Color(0xFFF3F3F5);
  static const muted = Color(0xFF6B6B70);
  static const line = Color(0xFFE4E4E7);
}

/// Tokens semânticos que mudam entre claro e escuro.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.ink,
    required this.muted,
    required this.line,
    required this.surface,
    required this.surfaceAlt,
    required this.glass,
    required this.glassBorder,
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.shadow,
    required this.mesh,
  });

  final Color ink;
  final Color muted;
  final Color line;
  final Color surface;
  final Color surfaceAlt;
  final Color glass;
  final Color glassBorder;
  final Color accent;
  final Color onAccent;
  final Color accentText;
  final Color shadow;
  final List<Color> mesh;

  static const light = AppTokens(
    ink: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.line,
    surface: Colors.white,
    surfaceAlt: Color(0xFFEEEEF0),
    glass: Color(0xB8FFFFFF),
    glassBorder: Color(0x33FFFFFF),
    accent: AppColors.leaf,
    onAccent: AppColors.ink,
    accentText: AppColors.forest,
    shadow: Color(0x1A000000),
    mesh: [
      Color(0xFFDDEFB0),
      Color(0xFFBFD9D2),
      Color(0xFFF1F1F3),
      Color(0xFFE7F3C7),
    ],
  );

  static const dark = AppTokens(
    ink: Color(0xFFF5F5F7),
    muted: Color(0xFF9A9AA0),
    line: Color(0xFF2C2C30),
    surface: Color(0xFF151517),
    surfaceAlt: Color(0xFF232326),
    glass: Color(0x9E1C1C1F),
    glassBorder: Color(0x1FFFFFFF),
    accent: AppColors.leaf,
    onAccent: AppColors.ink,
    accentText: AppColors.leaf,
    shadow: Color(0x66000000),
    mesh: [
      Color(0xFF1F3A12),
      Color(0xFF0F2C27),
      Color(0xFF050506),
      Color(0xFF2A3A0E),
    ],
  );

  @override
  AppTokens copyWith({
    Color? ink,
    Color? muted,
    Color? line,
    Color? surface,
    Color? surfaceAlt,
    Color? glass,
    Color? glassBorder,
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? shadow,
    List<Color>? mesh,
  }) {
    return AppTokens(
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentText: accentText ?? this.accentText,
      shadow: shadow ?? this.shadow,
      mesh: mesh ?? this.mesh,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      glass: l(glass, other.glass),
      glassBorder: l(glassBorder, other.glassBorder),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentText: l(accentText, other.accentText),
      shadow: l(shadow, other.shadow),
      mesh: [
        for (var i = 0; i < mesh.length; i++) l(mesh[i], other.mesh[i]),
      ],
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}

/// Raios no estilo One UI.
class AppRadius {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 26.0;
  static const xl = 32.0;
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppTokens.light);
  static ThemeData get dark => _build(Brightness.dark, AppTokens.dark);

  static ThemeData _build(Brightness brightness, AppTokens t) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? Colors.black : AppColors.paper;
    // Estilo Uber: primário monocromático (preto no claro, branco no escuro).
    final primary = isDark ? Colors.white : Colors.black;
    final onPrimary = isDark ? Colors.black : Colors.white;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.leaf,
      onSecondary: AppColors.ink,
      secondaryContainer: t.surfaceAlt,
      onSecondaryContainer: t.ink,
      surface: t.surface,
      onSurface: t.ink,
      onSurfaceVariant: t.muted,
      surfaceContainerHighest: t.surfaceAlt,
      outline: t.line,
      outlineVariant: t.line,
      error: isDark ? const Color(0xFFFF6B61) : const Color(0xFFB33D36),
    );

    final base = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final text = base
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        )
        .apply(bodyColor: t.ink, displayColor: t.ink);

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkRipple.splashFactory,
      extensions: [t],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: t.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        labelStyle: TextStyle(color: t.muted),
        floatingLabelStyle: TextStyle(color: t.ink),
        hintStyle: TextStyle(color: t.muted),
        prefixIconColor: t.ink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: t.ink, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: pill,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          foregroundColor: t.ink,
          side: BorderSide(color: t.line, width: 1.4),
          shape: pill,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: t.ink),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: t.surfaceAlt,
          foregroundColor: t.ink,
          selectedBackgroundColor: primary,
          selectedForegroundColor: onPrimary,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          visualDensity: VisualDensity.compact,
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceAlt,
        selectedColor: AppColors.leaf,
        checkmarkColor: AppColors.ink,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: t.ink),
        secondaryLabelStyle:
            text.labelLarge?.copyWith(color: AppColors.ink),
        iconTheme: IconThemeData(color: t.ink, size: 17),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.ink,
        textColor: t.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: t.ink),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C30) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
