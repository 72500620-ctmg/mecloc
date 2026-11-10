import 'package:flutter/material.dart';

/// Raios de borda padronizados do Design System MecLoc
class AppRadii {
  static const pill = 999.0;
  static const card = 16.0;
  static const modal = 24.0;
  static const floating = 18.0;
  static const sheet = 28.0;
  static const button = 14.0;
  static const chip = 10.0;
}

/// Azul MecLoc, grafite e neutros com contraste para leitura sobre o mapa.
class AppColors {
  // Primária: Azul Cobalto Automotivo (precisão, confiabilidade e alta legibilidade)
  static const cobaltPrimary = Color(0xFF0A58CA);
  static const cobaltDark = Color(0xFF073F94);
  static const cobaltElectric = Color(0xFF3880FF);
  static const cobaltLuminous = Color(0xFF60A5FA);

  // Neutros Claros (Clean Slate)
  static const slateCanvas = Color(0xFFF5F6F8);
  static const slateCard = Color(0xFFFFFFFF);
  static const slateBorder = Color(0xFFE2E8F0);
  static const slateMuted = Color(0xFF596579);
  static const slateInk = Color(0xFF17202E);

  // Neutros Escuros (OLED Midnight Zinc - estilo Apple / Uber Dark, conforto visual)
  static const darkCanvas = Color(0xFF0F1013);
  static const darkCard = Color(0xFF18191E);
  static const darkSubtle = Color(0xFF23252D);
  static const darkBorder = Color(0xFF2D303A);

  // Acentos Semânticos
  static const crimsonSos = Color(0xFFDC2626);
  static const coralRed = Color(0xFFEF4444);
  static const amberWarning = Color(0xFFF59E0B);
  static const amberGold = Color(0xFFD97706);
  static const emeraldWhatsApp = Color(0xFF10B981);
  static const emeraldDeep = Color(0xFF059669);

  // Aliases de compatibilidade para código legado (migrado para a nova paleta)
  static const forest = cobaltPrimary;
  static const forestDark = cobaltDark;
  static const leaf = cobaltElectric;
  static const leafGlow = cobaltLuminous;
  static const ink = slateInk;
  static const paper = slateCanvas;
  static const muted = slateMuted;
  static const line = slateBorder;
  static const electricBlue = cobaltElectric;
  static const darkBackground = darkCanvas;
  static const darkSurface = darkCard;
  static const darkLine = darkBorder;

  // Liquid Glass
  static Color glassBackgroundLight = Colors.white.withValues(alpha: 0.85);
  static Color glassBackgroundDark = darkCard.withValues(alpha: 0.85);
  static Color glassBorderLight = slateBorder.withValues(alpha: 0.8);
  static Color glassBorderDark = darkBorder.withValues(alpha: 0.8);
}

/// Extensão de tema com tokens semânticos de domínio do produto MecLoc
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.sos,
    required this.onSos,
    required this.whatsapp,
    required this.onWhatsapp,
    required this.warning,
    required this.onWarning,
    required this.surfaceSubtle,
    required this.borderSubtle,
    required this.compatibilityHigh,
    required this.compatibilityMedium,
    required this.compatibilityLow,
  });

  final Color sos;
  final Color onSos;
  final Color whatsapp;
  final Color onWhatsapp;
  final Color warning;
  final Color onWarning;
  final Color surfaceSubtle;
  final Color borderSubtle;
  final Color compatibilityHigh;
  final Color compatibilityMedium;
  final Color compatibilityLow;

  @override
  AppCustomColors copyWith({
    Color? sos,
    Color? onSos,
    Color? whatsapp,
    Color? onWhatsapp,
    Color? warning,
    Color? onWarning,
    Color? surfaceSubtle,
    Color? borderSubtle,
    Color? compatibilityHigh,
    Color? compatibilityMedium,
    Color? compatibilityLow,
  }) {
    return AppCustomColors(
      sos: sos ?? this.sos,
      onSos: onSos ?? this.onSos,
      whatsapp: whatsapp ?? this.whatsapp,
      onWhatsapp: onWhatsapp ?? this.onWhatsapp,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      compatibilityHigh: compatibilityHigh ?? this.compatibilityHigh,
      compatibilityMedium: compatibilityMedium ?? this.compatibilityMedium,
      compatibilityLow: compatibilityLow ?? this.compatibilityLow,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      sos: Color.lerp(sos, other.sos, t)!,
      onSos: Color.lerp(onSos, other.onSos, t)!,
      whatsapp: Color.lerp(whatsapp, other.whatsapp, t)!,
      onWhatsapp: Color.lerp(onWhatsapp, other.onWhatsapp, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      compatibilityHigh:
          Color.lerp(compatibilityHigh, other.compatibilityHigh, t)!,
      compatibilityMedium:
          Color.lerp(compatibilityMedium, other.compatibilityMedium, t)!,
      compatibilityLow:
          Color.lerp(compatibilityLow, other.compatibilityLow, t)!,
    );
  }
}

class AppTheme {
  static const AppCustomColors lightCustomColors = AppCustomColors(
    sos: AppColors.crimsonSos,
    onSos: Colors.white,
    whatsapp: AppColors.emeraldDeep,
    onWhatsapp: Colors.white,
    warning: AppColors.amberGold,
    onWarning: Colors.white,
    surfaceSubtle: Color(0xFFF1F5F9),
    borderSubtle: AppColors.slateBorder,
    compatibilityHigh: Color(0xFF047857),
    compatibilityMedium: Color(0xFFB45309),
    compatibilityLow: Color(0xFF64748B),
  );

  static const AppCustomColors darkCustomColors = AppCustomColors(
    sos: AppColors.coralRed,
    onSos: Colors.white,
    whatsapp: AppColors.emeraldWhatsApp,
    onWhatsapp: Colors.black,
    warning: AppColors.amberWarning,
    onWarning: Colors.black,
    surfaceSubtle: AppColors.darkSubtle,
    borderSubtle: AppColors.darkBorder,
    compatibilityHigh: Color(0xFF34D399),
    compatibilityMedium: Color(0xFFFBBF24),
    compatibilityLow: Color(0xFF94A3B8),
  );

  static ThemeData get light {
    const primary = AppColors.cobaltPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE0EDFF),
      onPrimaryContainer: const Color(0xFF001C47),
      secondary: const Color(0xFF334155),
      onSecondary: Colors.white,
      surface: AppColors.slateCard,
      onSurface: AppColors.slateInk,
      onSurfaceVariant: AppColors.slateMuted,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      outline: AppColors.slateBorder,
      outlineVariant: const Color(0xFFCBD5E1),
      error: AppColors.crimsonSos,
      onError: Colors.white,
    );

    return _refine(ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.slateCanvas,
      extensions: const [lightCustomColors],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.slateInk,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.slateInk,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.slateBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.slateBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
        hintStyle: const TextStyle(
          color: AppColors.slateMuted,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.slateBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.slateBorder, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        disabledColor: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        selectedColor: const Color(0xFFE0EDFF),
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          side: const BorderSide(color: Colors.transparent),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.slateInk,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFFE0EDFF),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: AppColors.slateMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.slateMuted,
          );
        }),
      ),
    ));
  }

  static ThemeData get dark {
    const primary = AppColors.cobaltLuminous;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cobaltElectric,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: const Color(0xFF0F172A),
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFDBEAFE),
      secondary: const Color(0xFF94A3B8),
      onSecondary: Colors.black,
      surface: AppColors.darkCard,
      onSurface: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFFAFB8C8),
      surfaceContainerHighest: AppColors.darkSubtle,
      outline: AppColors.darkBorder,
      outlineVariant: const Color(0xFF383C48),
      error: AppColors.coralRed,
      onError: Colors.white,
    );

    return _refine(ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      extensions: const [darkCustomColors],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8E95A5),
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSubtle,
        disabledColor: AppColors.darkSubtle.withValues(alpha: 0.5),
        selectedColor: const Color(0xFF1E3A8A),
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          side: const BorderSide(color: Colors.transparent),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF8FAFC),
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        indicatorColor: const Color(0xFF1E3A8A).withValues(alpha: 0.6),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: Color(0xFF8E95A5), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E95A5),
          );
        }),
      ),
    ));
  }

  static ThemeData _refine(ThemeData theme) {
    final colors = theme.colorScheme;
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: colors.onSurface),
        titleMedium: TextStyle(
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: colors.onSurface),
        titleSmall: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface),
        bodyMedium:
            TextStyle(fontSize: 14, height: 1.5, color: colors.onSurface),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        toolbarHeight: 72,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
      ),
      dividerTheme:
          DividerThemeData(color: colors.outline, thickness: 1, space: 1),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      )),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: colors.primaryContainer,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
            color: colors.primary, fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle:
            TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button)),
      ),
      tooltipTheme:
          const TooltipThemeData(waitDuration: Duration(milliseconds: 400)),
    );
  }
}

/// Helpers convenientes para acesso rápido a tokens do tema em qualquer Widget
extension BuildContextThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  AppCustomColors get customColors =>
      Theme.of(this).extension<AppCustomColors>() ?? AppTheme.lightCustomColors;
}
