import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';

import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notice.dart';
import '../widgets/emergency_modal.dart';
import '../widgets/workshop_list_tile.dart';
import '../widgets/workshop_pin_marker.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';
import 'quotes_screen.dart';
import 'workshop_detail_screen.dart';
import 'workshop_registration_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Widget _categoryChip(BuildContext context, WorkshopProvider provider,
      WorkshopCategory category, String label) {
    final selected = provider.selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => provider.setSelectedCategory(category),
    );
  }

  final _cityController = TextEditingController();
  final _mapController = MapController();
  LatLng? _lastCentered;
  bool _usingDeviceLocation = true;
  static const _initialCenter = LatLng(-15.7939, -47.8828);
  LatLng? _currentMapCenter;
  bool _showSearchThisArea = false;
  static const _distance = Distance();
  double _sheetExtent = 0.5;
  static const double _kMapFloatingPadding = 16.0;

  @override
  void dispose() {
    _cityController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchCity() async {
    final city = _cityController.text.trim();
    if (city.isNotEmpty) _usingDeviceLocation = false;
    context.read<WorkshopProvider>().setSearchQuery('');
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma cidade ou endereço para pesquisar.')),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showSearchThisArea = false);
    await context.read<WorkshopProvider>().searchWorkshops(city: city);
  }

  Future<void> _searchNearby() async {
    _cityController.clear();
    _usingDeviceLocation = true;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showSearchThisArea = false);
    await context.read<WorkshopProvider>().searchWorkshops();
  }

  Future<void> _searchThisArea() async {
    final targetCenter = _currentMapCenter;
    if (targetCenter == null) return;
    setState(() {
      _showSearchThisArea = false;
      _usingDeviceLocation = false;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await context
        .read<WorkshopProvider>()
        .searchWorkshops(customCenter: targetCenter);
  }

  void _openQuotes() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QuotesScreen()),
    );
  }

  void _openEmergencyModal() {
    EmergencyModal.show(
      context,
      onSelectCategory: (keyword, category) {
        final prov = context.read<WorkshopProvider>();
        if (category != null) {
          prov.setSelectedCategory(category);
        }
        if (keyword.isNotEmpty) {
          _cityController.text = keyword;
          prov.setSearchQuery(keyword);
        }
      },
    );
  }

  void _openWorkshopRegistration() {
    final searchCenter = context.read<WorkshopProvider>().searchCenter;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkshopRegistrationScreen(
          initialLatitude: searchCenter?.latitude,
          initialLongitude: searchCenter?.longitude,
        ),
      ),
    );
  }

  Future<void> _retrySearch() =>
      _cityController.text.trim().isEmpty ? _searchNearby() : _searchCity();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final vehicle = context.watch<VehicleProvider>().activeVehicle;
    final results = provider.getFilteredWorkshops(vehicle);
    final center = provider.searchCenter ?? _initialCenter;

    if (provider.searchCenter != null &&
        provider.searchCenter != _lastCentered) {
      _lastCentered = provider.searchCenter;
      _showSearchThisArea = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(center, 13);
      });
    }

    final markers = results
        .where((w) => w.latitude != null && w.longitude != null)
        .map((w) => Marker(
              point: LatLng(w.latitude!, w.longitude!),
              width: w.isCustomRegistered ? 56 : 50,
              height: w.isCustomRegistered ? 62 : 54,
              child: WorkshopPinMarker(
                workshop: w,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => WorkshopDetailScreen(workshop: w),
                  ),
                ),
              ),
            ))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 5,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  _currentMapCenter = camera.center;
                  final currentSearched = provider.searchCenter;
                  if (currentSearched != null) {
                    final dist = _distance.as(
                      LengthUnit.Meter,
                      currentSearched,
                      camera.center,
                    );
                    if (dist > 1500 && !_showSearchThisArea) {
                      setState(() => _showSearchThisArea = true);
                    }
                  }
                }
              },
              onMapReady: () {
                final current = provider.searchCenter;
                if (current != null) _mapController.move(current, 13);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mecloc',
                maxZoom: 19,
              ),
              MarkerLayer(markers: [
                if (_usingDeviceLocation && provider.searchCenter != null)
                  Marker(
                    point: provider.searchCenter!,
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.my_location,
                        color: Colors.blue, size: 30),
                  ),
                ...markers,
              ]),
              RichAttributionWidget(attributions: [
                TextSourceAttribution(
                  'OpenStreetMap',
                  onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                ),
              ]),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: _kMapFloatingPadding,
            right: _kMapFloatingPadding,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              color: Theme.of(context).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.floating),
                side: BorderSide(
                  color: isDark ? AppColors.darkLine : AppColors.line,
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: 56,
                child: TextField(
                  controller: _cityController,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) {
                    setState(() {});
                    context.read<WorkshopProvider>().setSearchQuery(value);
                  },
                  onSubmitted: (_) => _searchCity(),
                  decoration: InputDecoration(
                    filled: false,
                    hintText: 'Buscar cidade, bairro ou oficina...',
                    prefixIcon: IconButton(
                      tooltip: 'Buscar',
                      onPressed: _searchCity,
                      icon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_cityController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Limpar',
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _cityController.clear();
                              context
                                  .read<WorkshopProvider>()
                                  .setSearchQuery('');
                              setState(() {});
                            },
                          ),
                        Consumer<AuthProvider?>(
                          builder: (context, auth, _) {
                            final isAuthenticated = auth?.isAuthenticated ?? false;
                            final photoUrl = auth?.photoUrl;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  if (isAuthenticated) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const ProfileScreen(),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: AppColors.forest.withValues(alpha: 0.12),
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Icon(
                                          isAuthenticated
                                              ? Icons.person_rounded
                                              : Icons.person_outline_rounded,
                                          size: 20,
                                          color: AppColors.forest,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 56,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_showSearchThisArea)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  elevation: 5,
                  shadowColor:
                      Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                  color: Theme.of(context).colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? AppColors.darkLine : AppColors.line,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: provider.isLoading ? null : _searchThisArea,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buscar nesta área',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Botão flutuante SOS no mapa
          Positioned(
            right: _kMapFloatingPadding,
            top: MediaQuery.paddingOf(context).top + 80,
            child: Material(
              elevation: 4,
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openEmergencyModal,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: MediaQuery.paddingOf(context).top + 76,
            bottom: 0,
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((_sheetExtent - notification.extent).abs() > 0.005) {
                  setState(() => _sheetExtent = notification.extent);
                }
                return false;
              },
              child: DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.16,
              maxChildSize: 0.82,
              snap: true,
              snapSizes: const [0.5, 0.82],
              builder: (context, scrollController) => Material(
                elevation: 4,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.sheet)),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: 110 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.isLoading
                                    ? 'Procurando oficinas…'
                                    : provider.hasSearched
                                        ? 'Oficinas nesta região'
                                        : 'Cuide do seu carro por perto',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                provider.isLoading
                                    ? 'Aguarde enquanto consultamos o mapa.'
                                    : provider.hasSearched
                                        ? '${results.length} resultado(s) • dados do OpenStreetMap'
                                        : 'Encontre serviços automotivos e fale direto com a oficina.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (provider.isLoading)
                          const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ]),
                    ),
                    // BARRA DE AÇÕES RÁPIDAS: SOS, ORÇAMENTOS E CADASTRO
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.12),
                                foregroundColor: Colors.red.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: _openEmergencyModal,
                              icon: const Icon(Icons.warning_amber_rounded, size: 16),
                              label: const Text(
                                '🚨 Auto Socorro (SOS)',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                                foregroundColor: const Color(0xFF107C41),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: _openQuotes,
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: const Text(
                                'Orçamentos',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: _openWorkshopRegistration,
                              icon: const Icon(Icons.storefront_outlined, size: 16),
                              label: const Text(
                                'Sou Dono de Oficina',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (provider.errorMessage != null)
                      AppNotice(
                        title: 'Não foi possível concluir a busca',
                        message: provider.errorMessage!,
                        tone: AppNoticeTone.error,
                        action: TextButton(
                          onPressed: provider.isLoading ? null : _retrySearch,
                          child: const Text('Tentar novamente'),
                        ),
                      ),
                    if (provider.isLoading)
                      const AppNotice(
                        title: 'Atualizando esta região',
                        message:
                            'Estamos consultando localização e oficinas próximas.',
                        tone: AppNoticeTone.info,
                      ),
                    if (!provider.isLoading &&
                        provider.errorMessage == null &&
                        results.isEmpty &&
                        provider.hasSearched)
                      const AppNotice(
                        title: 'Nenhuma oficina encontrada',
                        message:
                            'Tente outra cidade ou mova o mapa para uma área próxima.',
                        tone: AppNoticeTone.warning,
                      ),
                    if (!provider.hasSearched)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Explore por tipo',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 10),
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              _categoryChip(context, provider,
                                  WorkshopCategory.mechanic, 'Mecânica'),
                              _categoryChip(context, provider,
                                  WorkshopCategory.carWash, 'Lava-jato'),
                              _categoryChip(context, provider,
                                  WorkshopCategory.tireShop, 'Pneus'),
                            ]),
                            const SizedBox(height: 18),
                            const Text(
                                'Os dados disponíveis variam por oficina. Confirme telefone, serviços e horário diretamente com o estabelecimento.'),
                          ],
                        ),
                      ),
                    if (!provider.isLoading)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          child: ListTile(
                            leading: const Icon(Icons.receipt_long_rounded, color: AppColors.forest),
                            title: const Text('Meus Orçamentos & Cotações'),
                            subtitle: const Text(
                                'Acompanhe suas solicitações e respostas via WhatsApp.'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _openQuotes,
                          ),
                        ),
                      ),
                    if (!provider.isLoading && results.isNotEmpty)
                      for (final workshop in results)
                        WorkshopListTile(workshop: workshop),
                  ],
                ),
              ),
            ),
            ),
          ),
          // Botão flutuante Minha Localização no canto inferior direito do mapa
          Positioned(
            right: _kMapFloatingPadding,
            bottom: (MediaQuery.sizeOf(context).height * _sheetExtent) + 14,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _sheetExtent > 0.75 ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _sheetExtent > 0.75,
                child: Material(
                  elevation: 4,
                  shadowColor:
                      Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  color: Theme.of(context).colorScheme.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: Tooltip(
                    message: 'Minha localização',
                    child: InkWell(
                      onTap: provider.isLoading ? null : _searchNearby,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkLine : AppColors.line,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
