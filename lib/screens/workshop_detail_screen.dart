import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'quotes_screen.dart';

class WorkshopDetailScreen extends StatelessWidget {
  const WorkshopDetailScreen({super.key, required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final isFavorite = provider.isFavorite(workshop.id);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    final primaryAction = FilledButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const QuotesScreen()),
      ),
      icon: const Icon(Icons.request_quote_outlined),
      label: const Text('Solicitar orçamento'),
    );
    final secondaryAction = workshop.openStreetMapUrl == null
        ? null
        : OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(workshop.openStreetMapUrl!)),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver no OpenStreetMap'),
          );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: isWide ? 320 : 260,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: GlassIconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
            title: const Glass(
              radius: 100,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Oficina'),
            ),
            actions: [
              GlassIconButton(
                tooltip:
                    isFavorite ? 'Remover dos favoritos' : 'Favoritar oficina',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  provider.toggleFavorite(workshop.id);
                },
                icon: FavoriteIcon(isFavorite: isFavorite, idleColor: t.ink),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.fadeTitle,
              ],
              background: ClipPath(
                clipper: _CurvedBottomClipper(),
                child: _HeaderBackground(workshop: workshop),
              ),
            ),
          ),
          SliverPadding(
            padding: contentPadding(context, top: 8, bottom: 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'workshop-badge-${workshop.id}',
                          child: const IconBadge(
                            icon: Icons.handyman_rounded,
                            size: 60,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            workshop.name,
                            style: text.headlineMedium,
                          ),
                        ),
                      ],
                    ),
                  FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    const SizedBox(height: 20),
                    AppSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (workshop.rating != null)
                            _InfoLine(
                              icon: Icons.star_rounded,
                              text:
                                  '${workshop.rating!.toStringAsFixed(1)}${workshop.ratingCount == null ? '' : ' · ${workshop.ratingCount} avaliações'}',
                            ),
                          _InfoLine(
                            icon: Icons.location_on_outlined,
                            text: workshop.address,
                          ),
                          if (workshop.phone != null)
                            _InfoLine(
                              icon: Icons.phone_outlined,
                              text: workshop.phone!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Informações', style: text.titleLarge),
                    const SizedBox(height: 10),
                    AppSurface(
                      color: t.surfaceAlt,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: t.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dados colaborativos do OpenStreetMap podem estar incompletos. '
                              'Confirme endereço, serviços, horários e valores diretamente com a oficina.',
                              style: text.bodyMedium?.copyWith(
                                color: t.muted,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isWide)
                      Row(
                        children: [
                          Expanded(child: PressableScale(child: primaryAction)),
                          if (secondaryAction != null) ...[
                            const SizedBox(width: 12),
                            Expanded(child: secondaryAction),
                          ],
                        ],
                      )
                    else ...[
                      PressableScale(child: primaryAction),
                      if (secondaryAction != null) ...[
                        const SizedBox(height: 10),
                        secondaryAction,
                      ],
                    ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fundo do cabeçalho: mini-mapa (sem interação) ou gradient mesh.
class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final hasPoint = workshop.latitude != null && workshop.longitude != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasPoint)
          IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(workshop.latitude!, workshop.longitude!),
                initialZoom: 16,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mecloc',
                  maxZoom: 19,
                  tileBuilder: isDark ? darkModeTileBuilder : null,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(workshop.latitude!, workshop.longitude!),
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.handyman_rounded,
                          color: isDark ? Colors.black : AppColors.leaf,
                        ),
                      ),
                    ),
                  ],
                ),
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap contributors'),
                  alignment: Alignment.topRight,
                ),
              ],
            ),
          )
        else
          const GradientMesh(),
        // Degradê inferior para fundir com o conteúdo.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.55, 1],
              colors: [background.withValues(alpha: 0), background],
            ),
          ),
        ),
      ],
    );
  }
}

/// Recorte curvo na base do cabeçalho (CustomClipper).
class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const curve = 36.0;
    return Path()
      ..lineTo(0, size.height - curve)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curve * 0.6,
        size.width,
        size.height - curve,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: t.ink),
      ),
      title: Text(text),
    );
  }
}
