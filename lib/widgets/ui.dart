import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

/// Largura máxima do conteúdo em telas largas (desktop/Chrome).
const kContentMaxWidth = 760.0;

/// Padding horizontal que centraliza o conteúdo em telas largas.
EdgeInsets contentPadding(
  BuildContext context, {
  double top = 0,
  double bottom = 24,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = math.max(16.0, (width - kContentMaxWidth) / 2);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

/// Vidro fosco (Glassmorphism) com BackdropFilter + ImageFilter.blur.
/// Use com moderação: cada camada custa GPU no Chrome.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = AppRadius.md,
    this.padding = EdgeInsets.zero,
    this.blur = 18,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: t.glass,
              borderRadius: shape,
              border: Border.all(color: t.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Encolhe levemente ao pressionar e volta com física de mola.
/// Usa Listener, então não rouba o toque de InkWell/IconButton filhos.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.pressedScale = 0.96});

  final Widget child;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 520, damping: 24);
  late final AnimationController _controller =
      AnimationController.unbounded(vsync: this, value: 1);

  void _springTo(double target) {
    _controller.animateWith(
      SpringSimulation(_spring, _controller.value, target, _controller.velocity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _springTo(widget.pressedScale),
      onPointerUp: (_) => _springTo(1),
      onPointerCancel: (_) => _springTo(1),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Cartão sólido de cantos grandes (One UI) com sombra suave.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.lg,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shape = BorderRadius.circular(radius);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: isDark ? Border.all(color: t.line) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: t.shadow.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: color ?? t.surface,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? surface : PressableScale(child: surface);
  }
}

/// Quadrado arredondado com ícone (avatar de oficina).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 48,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? t.accent,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: foreground ?? t.onAccent, size: size * 0.5),
    );
  }
}

/// Entrada suave (fade + slide) com TweenAnimationBuilder.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = math.min(index, 8) * 45;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Brilho que corre por cima dos skeletons (ShaderMask + AnimationController).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.85);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [t.surfaceAlt, highlight, t.surfaceAlt],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlideGradient(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);
  final double percent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 10});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lista fantasma exibida enquanto as oficinas carregam.
class WorkshopSkeletonList extends StatelessWidget {
  const WorkshopSkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppSurface(
              padding: const EdgeInsets.all(16),
              radius: AppRadius.md,
              // Shimmer só nos blocos, não no cartão inteiro.
              child: Shimmer(
                child: Row(
                  children: [
                    const SkeletonBox(width: 48, height: 48, radius: 15),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120.0 + (i % 3) * 30, height: 14),
                          const SizedBox(height: 8),
                          const SkeletonBox(height: 11),
                          const SizedBox(height: 6),
                          const SkeletonBox(width: 90, height: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fundo em "gradient mesh" desenhado com CustomPainter.
/// A animação roda uma vez só (não trava pumpAndSettle nos testes).
class GradientMesh extends StatelessWidget {
  const GradientMesh({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final background = Theme.of(context).scaffoldBackgroundColor;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) => CustomPaint(
        painter: _MeshPainter(colors: t.mesh, background: background, progress: value, dot: t.line),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.colors,
    required this.background,
    required this.progress,
    required this.dot,
  });

  final List<Color> colors;
  final Color background;
  final double progress;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final shortest = size.shortestSide;
    final blobs = <(Offset, double, Color)>[
      (Offset(size.width * (0.82 - 0.06 * progress), size.height * 0.18), shortest * 0.75, colors[0]),
      (Offset(size.width * 0.18, size.height * (0.30 + 0.05 * progress)), shortest * 0.65, colors[1]),
      (Offset(size.width * (0.55 + 0.05 * progress), size.height * 0.78), shortest * 0.85, colors[3]),
      (Offset(size.width * 0.95, size.height * 0.95), shortest * 0.5, colors[2]),
    ];
    for (final (center, radius, color) in blobs) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.95 * progress), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
    // Grade de pontos discreta, lembrando um mapa.
    final dots = Paint()..color = dot.withValues(alpha: 0.55 * progress);
    const gap = 28.0;
    for (var x = gap / 2; x < size.width; x += gap) {
      for (var y = gap / 2; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, dots);
      }
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) =>
      old.progress != progress || old.background != background || old.colors != colors;
}

/// Logo "MecLoc" com degradê via ShaderMask.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBadge(icon: Icons.handyman_rounded, size: size + 12),
        const SizedBox(width: 8),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [t.ink, t.accentText],
          ).createShader(bounds),
          child: Text(
            'MecLoc',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// Botão redondo de vidro (para usar por cima de mapas/imagens).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 100,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: color,
        icon: icon,
      ),
    );
  }
}

/// Alterna claro/escuro com ícone animado.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Modo claro' : 'Modo escuro',
      onPressed: () {
        HapticFeedback.selectionClick();
        context.read<ThemeController>().toggle(brightness);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween(begin: 0.6, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(isDark),
        ),
      ),
    );
  }
}

/// Puxador do bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.tokens.line,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Coração de favorito com troca animada.
class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({super.key, required this.isFavorite, this.idleColor});

  final bool isFavorite;
  final Color? idleColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
      child: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        key: ValueKey(isFavorite),
        color: isFavorite ? const Color(0xFFFF4D5E) : (idleColor ?? context.tokens.muted),
      ),
    );
  }
}
