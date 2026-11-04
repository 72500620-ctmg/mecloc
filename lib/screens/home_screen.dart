import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'quotes_screen.dart';
import 'vehicle_screen.dart';
import 'workshop_detail_screen.dart';

/// Largura a partir da qual a Home vira layout de desktop (painel + mapa).
const _kWideBreakpoint = 900.0;
const _kPanelWidth = 430.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cityController = TextEditingController();
  bool _favoritesOnly = false;
  bool _showMap = true;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await context.read<WorkshopProvider>().searchWorkshops(
          city: _cityController.text,
        );
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  bool _isMapVisible(WorkshopProvider provider, List<Workshop> workshops) {
    return _showMap &&
        provider.hasSearched &&
        !provider.isLoading &&
        provider.errorMessage == null &&
        workshops.isNotEmpty &&
        provider.searchCenter != null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final workshops = provider.workshops
        .where(
            (workshop) => !_favoritesOnly || provider.isFavorite(workshop.id))
        .toList();
    final isWide = MediaQuery.sizeOf(context).width >= _kWideBreakpoint;
    final mapVisible = _isMapVisible(provider, workshops);
    final center = provider.searchCenter;

    final map = mapVisible
        ? _WorkshopMap(
            key: ValueKey('map-${center!.latitude},${center.longitude}'),
            center: center,
            workshops: workshops,
            onWorkshopSelected: (workshop) => _open(
              WorkshopDetailScreen(workshop: workshop),
            ),
          )
        : null;

    final slivers = _panelSlivers(provider, workshops);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GradientMesh()),
          if (isWide)
            // Desktop (Uber web): mapa à direita, painel à esquerda.
            Positioned(
              left: _kPanelWidth + 32,
              top: 88,
              right: 16,
              bottom: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: map == null
                    ? _WideHero(key: ValueKey(provider.hasSearched))
                    : ClipRRect(
                        key: const ValueKey('map'),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: map,
                      ),
              ),
            )
          else
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: map ?? const SizedBox.shrink(),
              ),
            ),
          if (isWide)
            Positioned(
              left: 16,
              top: 88,
              bottom: 16,
              width: _kPanelWidth,
              child: _WidePanel(slivers: slivers),
            )
          else
            Positioned.fill(child: _NarrowSheet(slivers: slivers)),
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _TopBar(
                  onQuotes: () => _open(const QuotesScreen()),
                  onVehicle: () => _open(const VehicleScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _panelSlivers(
    WorkshopProvider provider,
    List<Workshop> workshops,
  ) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final showControls = provider.hasSearched && provider.errorMessage == null;
    final showList = provider.hasSearched &&
        !provider.isLoading &&
        provider.errorMessage == null &&
        workshops.isNotEmpty &&
        !_showMap;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Oficinas perto de você', style: text.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Busque usando sua localização ou informe uma cidade.',
                style: text.bodyMedium?.copyWith(color: t.muted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _cityController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  labelText: 'Cidade (opcional)',
                  hintText: 'Vazio: usar localização atual',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              PressableScale(
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: provider.isLoading ? null : _search,
                    icon: const Icon(Icons.near_me_rounded),
                    label: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _cityController.text.trim().isEmpty
                            ? 'Buscar perto de mim'
                            : 'Buscar na cidade',
                        key: ValueKey(_cityController.text.trim().isEmpty),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: t.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'A localização ou cidade informada será enviada ao '
                      'OpenStreetMap para esta busca.',
                      style: text.bodySmall?.copyWith(color: t.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  provider.isLoading
                      ? 'Buscando oficinas...'
                      : provider.hasSearched
                          ? '${workshops.length} oficinas encontradas'
                          : 'Encontre oficinas',
                  key: ValueKey(
                    '${provider.isLoading}-${provider.hasSearched}-${workshops.length}',
                  ),
                  style: text.titleMedium,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: showControls
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SegmentedButton<bool>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  icon: Icon(Icons.map_outlined),
                                  label: Text('Mapa'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  icon: Icon(Icons.list),
                                  label: Text('Lista'),
                                ),
                              ],
                              selected: {_showMap},
                              onSelectionChanged: (selection) {
                                HapticFeedback.selectionClick();
                                setState(() => _showMap = selection.first);
                              },
                            ),
                            FilterChip(
                              selected: _favoritesOnly,
                              showCheckmark: false,
                              label: const Text('Favoritas'),
                              avatar: Icon(
                                Icons.favorite,
                                size: 17,
                                color: _favoritesOnly ? AppColors.ink : t.ink,
                              ),
                              onSelected: (value) {
                                HapticFeedback.selectionClick();
                                setState(() => _favoritesOnly = value);
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      if (showList)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: workshops.length,
            itemBuilder: (context, index) => FadeSlideIn(
              key: ValueKey(workshops[index].id),
              index: index,
              child: _WorkshopTile(workshop: workshops[index]),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              child: _buildState(provider, workshops),
            ),
          ),
        ),
    ];
  }

  Widget _buildState(WorkshopProvider provider, List<Workshop> workshops) {
    if (!provider.hasSearched) {
      return const _MessageState(
        key: ValueKey('idle'),
        icon: Icons.map_outlined,
        title: 'Veja oficinas no mapa',
        message:
            'Use sua localização atual ou informe uma cidade para começar.',
      );
    }
    if (provider.isLoading) {
      return const WorkshopSkeletonList(key: ValueKey('loading'));
    }
    if (provider.errorMessage != null) {
      return _MessageState(
        key: const ValueKey('error'),
        icon: Icons.wifi_off_outlined,
        title: 'Não foi possível carregar as oficinas',
        message: provider.errorMessage!,
        actionLabel: 'Tentar novamente',
        onAction: () => provider.searchWorkshops(
          city: _cityController.text,
        ),
      );
    }
    if (workshops.isEmpty) {
      return _MessageState(
        key: ValueKey('empty-$_favoritesOnly'),
        icon: _favoritesOnly ? Icons.favorite_border : Icons.build_outlined,
        title: _favoritesOnly
            ? 'Nenhuma oficina favorita nesta busca'
            : 'Nenhuma oficina encontrada',
        message: 'Tente outra cidade ou busque usando sua localização.',
      );
    }
    if (provider.searchCenter == null) {
      return const _MessageState(
        key: ValueKey('no-center'),
        icon: Icons.map_outlined,
        title: 'Mapa indisponível',
        message: 'Faça uma nova busca para localizar as oficinas.',
      );
    }
    // Modo mapa: o mapa está no fundo; aqui fica só a dica.
    return _MessageState(
      key: const ValueKey('map-hint'),
      icon: Icons.touch_app_outlined,
      title: 'Toque em um pin no mapa',
      message: 'Cada pin abre os detalhes da oficina.',
      actionLabel: '© OpenStreetMap contributors',
      onAction: () => launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
      ),
    );
  }
}

/// Área direita do desktop antes de o mapa aparecer.
class _WideHero extends StatelessWidget {
  const _WideHero({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 48),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: FadeSlideIn(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A oficina certa,\nperto de você.',
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.6,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dados abertos do OpenStreetMap, direto no mapa.',
                  style: text.titleMedium?.copyWith(
                    color: t.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra flutuante de vidro: marca à esquerda, ações à direita.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onQuotes, required this.onVehicle});

  final VoidCallback onQuotes;
  final VoidCallback onVehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Glass(
          radius: 100,
          padding: EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: BrandWordmark(),
        ),
        const Spacer(),
        Glass(
          radius: 100,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThemeToggleButton(),
              IconButton(
                tooltip: 'Orçamentos',
                onPressed: onQuotes,
                icon: const Icon(Icons.request_quote_outlined),
              ),
              IconButton(
                tooltip: 'Meu veículo',
                onPressed: onVehicle,
                icon: const Icon(Icons.directions_car_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Desktop: painel flutuante à esquerda, estilo Uber web.
class _WidePanel extends StatelessWidget {
  const _WidePanel({required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 40, offset: const Offset(0, 16)),
        ],
      ),
      child: Material(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ...slivers,
          ],
        ),
      ),
    );
  }
}

/// Mobile/janela estreita: bottom sheet arrastável sobre o mapa.
class _NarrowSheet extends StatelessWidget {
  const _NarrowSheet({required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DraggableScrollableSheet(
      initialChildSize: 0.56,
      minChildSize: 0.22,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.56],
      builder: (context, controller) => DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: [
            BoxShadow(color: t.shadow, blurRadius: 30, offset: const Offset(0, -6)),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          child: Material(
            type: MaterialType.transparency,
            // Permite arrastar o sheet com o mouse no Chrome.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  const SliverToBoxAdapter(child: SheetHandle()),
                  ...slivers,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopMap extends StatelessWidget {
  const _WorkshopMap({
    super.key,
    required this.center,
    required this.workshops,
    required this.onWorkshopSelected,
  });

  final LatLng center;
  final List<Workshop> workshops;
  final ValueChanged<Workshop> onWorkshopSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markers = workshops
        .where((workshop) =>
            workshop.latitude != null && workshop.longitude != null)
        .map(
          (workshop) => Marker(
            point: LatLng(workshop.latitude!, workshop.longitude!),
            width: 52,
            height: 52,
            child: PressableScale(
              pressedScale: 0.85,
              child: GestureDetector(
                onTap: () => onWorkshopSelected(workshop),
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Abrir oficina',
                    child: _MapPin(),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        backgroundColor: isDark ? const Color(0xFF0E0E10) : const Color(0xFFE9E9EC),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mecloc',
          maxZoom: 19,
          tileBuilder: isDark ? darkModeTileBuilder : null,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 28,
              height: 28,
              child: const _CenterDot(),
            ),
            ...markers,
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {
                launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Pin estilo Uber: círculo escuro com borda branca.
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.black : AppColors.leaf;
    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.black : Colors.white,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(Icons.handyman_rounded, size: 20, color: iconColor),
      ),
    );
  }
}

/// Ponto do centro da busca.
class _CenterDot extends StatelessWidget {
  const _CenterDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.leaf.withValues(alpha: 0.3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.leaf,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }
}

class _WorkshopTile extends StatelessWidget {
  const _WorkshopTile({required this.workshop});

  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final isFavorite = provider.isFavorite(workshop.id);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppSurface(
        padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
        radius: AppRadius.md,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => WorkshopDetailScreen(workshop: workshop),
          ),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'workshop-badge-${workshop.id}',
              child: const IconBadge(icon: Icons.handyman_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workshop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    workshop.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: t.muted),
                  ),
                  if (workshop.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFFFB300)),
                        const SizedBox(width: 3),
                        Text(
                          workshop.rating!.toStringAsFixed(1),
                          style: text.labelMedium,
                        ),
                        if (workshop.ratingCount != null)
                          Text(
                            ' (${workshop.ratingCount})',
                            style: text.labelMedium?.copyWith(color: t.muted),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.toggleFavorite(workshop.id);
              },
              icon: FavoriteIcon(isFavorite: isFavorite),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return AppSurface(
      color: t.surfaceAlt,
      radius: AppRadius.md,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: t.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: t.ink),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: text.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: t.muted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
