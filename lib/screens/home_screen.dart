import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import 'quotes_screen.dart';
import 'vehicle_screen.dart';
import 'workshop_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final workshops = provider.workshops
        .where(
            (workshop) => !_favoritesOnly || provider.isFavorite(workshop.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.handyman_outlined, color: AppColors.forest),
            SizedBox(width: 8),
            Text('MecLoc', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Orçamentos',
            onPressed: () => _open(const QuotesScreen()),
            icon: const Icon(Icons.request_quote_outlined),
          ),
          IconButton(
            tooltip: 'Meu veículo',
            onPressed: () => _open(const VehicleScreen()),
            icon: const Icon(Icons.directions_car_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oficinas perto de você',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Busque usando sua localização ou informe uma cidade.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: provider.isLoading ? null : _search,
                      icon: const Icon(Icons.near_me_outlined),
                      label: Text(_cityController.text.trim().isEmpty
                          ? 'Buscar perto de mim'
                          : 'Buscar na cidade'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A localização ou cidade informada será enviada ao '
                    'OpenStreetMap para esta busca.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.isLoading
                          ? 'Buscando oficinas...'
                          : provider.hasSearched
                              ? '${workshops.length} oficinas encontradas'
                              : 'Encontre oficinas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (provider.hasSearched &&
                      provider.errorMessage == null) ...[
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
                      onSelectionChanged: (selection) =>
                          setState(() => _showMap = selection.first),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _favoritesOnly,
                      label: const Text('Favoritas'),
                      avatar: const Icon(Icons.favorite, size: 17),
                      onSelected: (value) =>
                          setState(() => _favoritesOnly = value),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: _buildResults(provider, workshops)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(WorkshopProvider provider, List<Workshop> workshops) {
    if (!provider.hasSearched) {
      return const _MessageState(
        icon: Icons.map_outlined,
        title: 'Veja oficinas no mapa',
        message:
            'Use sua localização atual ou informe uma cidade para começar.',
      );
    }
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null) {
      return _MessageState(
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
        icon: _favoritesOnly ? Icons.favorite_border : Icons.build_outlined,
        title: _favoritesOnly
            ? 'Nenhuma oficina favorita nesta busca'
            : 'Nenhuma oficina encontrada',
        message: 'Tente outra cidade ou busque usando sua localização.',
      );
    }

    if (_showMap) {
      final center = provider.searchCenter;
      if (center == null) {
        return const _MessageState(
          icon: Icons.map_outlined,
          title: 'Mapa indisponível',
          message: 'Faça uma nova busca para localizar as oficinas.',
        );
      }
      return _WorkshopMap(
        center: center,
        workshops: workshops,
        onWorkshopSelected: (workshop) => _open(
          WorkshopDetailScreen(workshop: workshop),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: workshops.length,
      itemBuilder: (context, index) =>
          _WorkshopTile(workshop: workshops[index]),
    );
  }
}

class _WorkshopMap extends StatelessWidget {
  const _WorkshopMap({
    required this.center,
    required this.workshops,
    required this.onWorkshopSelected,
  });

  final LatLng center;
  final List<Workshop> workshops;
  final ValueChanged<Workshop> onWorkshopSelected;

  @override
  Widget build(BuildContext context) {
    final markers = workshops
        .where((workshop) =>
            workshop.latitude != null && workshop.longitude != null)
        .map(
          (workshop) => Marker(
            point: LatLng(workshop.latitude!, workshop.longitude!),
            width: 44,
            height: 48,
            child: GestureDetector(
              onTap: () => onWorkshopSelected(workshop),
              child: const Tooltip(
                message: 'Abrir oficina',
                child: Icon(
                  Icons.location_on,
                  color: AppColors.forest,
                  size: 42,
                ),
              ),
            ),
          ),
        )
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mecloc',
            maxZoom: 19,
          ),
          MarkerLayer(markers: markers),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => WorkshopDetailScreen(workshop: workshop),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman, color: AppColors.forest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workshop.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (workshop.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 15, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(workshop.rating!.toStringAsFixed(1)),
                          if (workshop.ratingCount != null)
                            Text(
                              ' (${workshop.ratingCount})',
                              style: const TextStyle(color: AppColors.muted),
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
                onPressed: () => provider.toggleFavorite(workshop.id),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
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
      ),
    );
  }
}
