import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Container com efeito translúcido Liquid Glass (Apple-inspired glassmorphism)
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurSigma = 16.0,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(22);

    final defaultColor = color ??
        (isDark ? AppColors.glassBackgroundDark : AppColors.glassBackgroundLight);

    final defaultBorderColor = borderColor ??
        (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    final defaultShadows = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: defaultColor,
              borderRadius: radius,
              border: Border.all(
                color: defaultBorderColor,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.70),
                        Colors.white.withValues(alpha: 0.35),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Botão flutuante em Liquid Glass
class LiquidGlassIconButton extends StatelessWidget {
  const LiquidGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 46.0,
    this.iconSize = 22.0,
    this.iconColor,
    this.badgeText,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? Colors.white : AppColors.ink);

    Widget button = InkWell(
      borderRadius: BorderRadius.circular(size / 2),
      onTap: onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            if (badgeText != null && badgeText!.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.coralRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return LiquidGlassContainer(
      borderRadius: BorderRadius.circular(size / 2),
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: button,
      ),
    );
  }
}

/// Badge / Pill com acabamento vítreo
class LiquidGlassBadge extends StatelessWidget {
  const LiquidGlassBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.textColor,
    this.fontSize = 11.5,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.forest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: textColor ?? effectiveColor),
            const SizedBox(width: 4.5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor ?? effectiveColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

