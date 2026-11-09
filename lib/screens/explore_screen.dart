import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
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
import 'main_shell.dart';
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
  final _cityController = TextEditingController();
  final _mapController = MapController();
  LatLng? _lastCentered;
  bool _usingDeviceLocation = true;
  static const _initialCenter = LatLng(-15.7939, -47.8828);
  static const _distance = Distance();

  // Constantes de layout do Design System
  static const double _kMapFloatingPadding = 16.0;
  static const String _stadiaApiKey = String.fromEnvironment(
    'STADIA_MAPS_API_KEY',
    defaultValue: 'ab593839-51bf-4a1a-9195-a991991eab52',
  );
  double _sheetExtent = 0.45;
  double _mapRotation = 0.0;

  // Busca automática inteligente ao mover o mapa
  Timer? _autoSearchDebounce;
  LatLng? _lastAutoSearchedCenter;
  double _lastZoom = 13.0;

  @override
  void dispose() {
    _autoSearchDebounce?.cancel();
    _cityController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCameraMoved(LatLng newCenter, double newZoom) {
    // 1. Se a alteração de câmera foi apenas de zoom (sem deslocamento significativo do centro),
    // NÃO dispara busca automática nem considera como mudança de localidade geográfica.
    final zoomChanged = (_lastZoom - newZoom).abs() > 0.05;
    _lastZoom = newZoom;

    final searchCenter = context.read<WorkshopProvider>().searchCenter;
    final reference = _lastAutoSearchedCenter ?? searchCenter;
    if (reference != null) {
      final dist = _distance.as(LengthUnit.Meter, reference, newCenter);
      // Se moveu menos de 1.2km, não refaz a busca
      if (dist < 1200) return;
    }

    // Se o usuário apenas alterou o zoom sem deslocar o centro geográfico acima do limiar,
    // não precisamos reconsultar a API de oficinas.
    if (zoomChanged && reference != null) {
      final dist = _distance.as(LengthUnit.Meter, reference, newCenter);
      if (dist < 1200) return;
    }

    _autoSearchDebounce?.cancel();
    _autoSearchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      _lastAutoSearchedCenter = newCenter;
      await context
          .read<WorkshopProvider>()
          .searchWorkshops(customCenter: newCenter);
    });
  }

  Future<void> _performSearch() async {
    final query = _cityController.text.trim();
    if (query.isEmpty) {
      _searchNearby();
      return;
    }

    _usingDeviceLocation = false;
    FocusManager.instance.primaryFocus?.unfocus();

    final provider = context.read<WorkshopProvider>();
    provider.setSearchQuery(query);

    // 1. Se já existem oficinas correspondentes carregadas na memória,
    // apenas centraliza na primeira correspondência no mapa e destaca.
    // Isso evita refazer requisições desnecessárias, buscar cidades distantes
    // ou substituir os resultados locais que o usuário já estava vendo ao digitar.
    final localMatches = provider.getFilteredWorkshops(null);
    if (localMatches.isNotEmpty) {
      final firstWithCoords = localMatches.firstWhere(
        (w) => w.latitude != null && w.longitude != null,
        orElse: () => localMatches.first,
      );
      if (firstWithCoords.latitude != null && firstWithCoords.longitude != null) {
        final target = LatLng(firstWithCoords.latitude!, firstWithCoords.longitude!);
        _mapController.move(target, 15.0);
        provider.selectWorkshop(firstWithCoords);
      }
      return;
    }

    // 2. Se não encontrou nenhuma oficina correspondente na memória local,
    // realiza a busca remota inteligente (por nome de oficina na região, ou cidade/bairro).
    await provider.searchWorkshops(query: query);

    if (mounted && provider.searchCenter != null) {
      _mapController.move(provider.searchCenter!, 14.0);
    }
  }

  Future<void> _searchNearby() async {
    _cityController.clear();
    _usingDeviceLocation = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final provider = context.read<WorkshopProvider>();
    // Se a localização do dispositivo já estiver disponível, move a câmera imediatamente sem esperar
    if (provider.deviceLocation != null) {
      _mapController.move(provider.deviceLocation!, 14.5);
    }
    await provider.searchWorkshops();
    if (mounted && provider.deviceLocation != null) {
      _mapController.move(provider.deviceLocation!, 14.5);
    }
  }

  Future<void> _retrySearch() =>
      _cityController.text.trim().isEmpty ? _searchNearby() : _performSearch();

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

  void _openWorkshopRegistration({String? prefilledName}) {
    final searchCenter = context.read<WorkshopProvider>().searchCenter;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkshopRegistrationScreen(
          initialName: prefilledName,
          initialLatitude: searchCenter?.latitude,
          initialLongitude: searchCenter?.longitude,
        ),
      ),
    );
  }

  void _clearFilters() {
    _cityController.clear();
    final provider = context.read<WorkshopProvider>();
    provider.setSearchQuery('');
    provider.setSelectedCategory(null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top;
    final provider = context.watch<WorkshopProvider>();
    final authProvider = context.watch<AuthProvider>();
    final vehicle = context.watch<VehicleProvider>().activeVehicle;
    final results = provider.getFilteredWorkshops(vehicle);
    final center = provider.deviceLocation ?? provider.searchCenter ?? _initialCenter;

    final isSearching = _cityController.text.trim().isNotEmpty ||
        provider.selectedCategory != null ||
        provider.searchQuery.trim().isNotEmpty;

    final markers = results
        .where((w) => w.latitude != null && w.longitude != null)
        .map((w) => Marker(
              point: LatLng(w.latitude!, w.longitude!),
              width: w.isCustomRegistered ? 56 : 50,
              height: w.isCustomRegistered ? 62 : 54,
              rotate: true,
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
          // 1. MAPA INTERATIVO (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              onPositionChanged: (camera, hasGesture) {
                if ((_mapRotation - camera.rotation).abs() > 0.5) {
                  setState(() {
                    _mapRotation = camera.rotation;
                  });
                }
                if (hasGesture) {
                  _onMapCameraMoved(camera.center, camera.zoom);
                }
              },
              onMapReady: () {
                final current = provider.deviceLocation ?? provider.searchCenter;
                if (current != null) _mapController.move(current, 13);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _stadiaApiKey.isNotEmpty
                    ? (isDark
                        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey'
                        : 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey')
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mecloc',
                maxZoom: 20,
                tileBuilder: (_stadiaApiKey.isEmpty && isDark) ? darkModeTileBuilder : null,
              ),
              CurrentLocationLayer(
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: AppColors.cobaltPrimary,
                    child: Icon(Icons.navigation, color: Colors.white, size: 12),
                  ),
                  markerSize: Size(26, 26),
                  accuracyCircleColor: Color(0x251D4ED8),
                ),
              ),
              MarkerLayer(
                rotate: true,
                markers: markers,
              ),
              RichAttributionWidget(attributions: [
                TextSourceAttribution(
                  _stadiaApiKey.isNotEmpty
                      ? 'Stadia Maps © OpenMapTiles © OpenStreetMap'
                      : 'OpenStreetMap',
                  onTap: () => launchUrl(
                    Uri.parse(_stadiaApiKey.isNotEmpty
                        ? 'https://stadiamaps.com/'
                        : 'https://www.openstreetmap.org/copyright'),
                  ),
                ),
              ]),
            ],
          ),

          // 2. BARRA DE PESQUISA FLUTUANTE COM LOADING CONJUGADO
          Positioned(
            top: topInset + 12,
            left: _kMapFloatingPadding,
            right: _kMapFloatingPadding,
            child: Material(
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              color: Theme.of(context).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.floating),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
                  width: 1.2,
                ),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 56,
                    child: TextField(
                      controller: _cityController,
                      textAlignVertical: TextAlignVertical.center,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {});
                        context.read<WorkshopProvider>().setSearchQuery(value);
                      },
                      onSubmitted: (_) => _performSearch(),
                      decoration: InputDecoration(
                        filled: false,
                        hintText: 'Buscar oficina, bairro ou serviço...',
                        prefixIcon: IconButton(
                          tooltip: 'Buscar',
                          onPressed: _performSearch,
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
                                tooltip: 'Limpar busca',
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _cityController.clear();
                                  context.read<WorkshopProvider>().setSearchQuery('');
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
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      backgroundImage: photoUrl != null
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl == null
                                          ? Icon(
                                              isAuthenticated
                                                  ? Icons.person_rounded
                                                  : Icons.person_outline_rounded,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
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
                  // Barra de loading conjugada na base do container de busca
                  if (provider.isLoading)
                    const LinearProgressIndicator(
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                    ),
                ],
              ),
            ),
          ),

          // 3. BOTÃO FLUTUANTE SOS NO MAPA (com margem padronizada)
          Positioned(
            right: _kMapFloatingPadding,
            top: topInset + 80,
            child: Material(
              elevation: 4,
              color: AppColors.crimsonSos,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openEmergencyModal,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'SOS 24h',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. BOTTOM SHEET INTELIGENTE (Mutação: Discovery Hub vs Search Results)
          Positioned.fill(
            top: topInset + 76,
            bottom: 0,
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((_sheetExtent - notification.extent).abs() > 0.005) {
                  setState(() => _sheetExtent = notification.extent);
                }
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: isSearching ? 0.6 : 0.45,
                minChildSize: 0.16,
                maxChildSize: 0.88,
                snap: true,
                snapSizes: const [0.16, 0.45, 0.6, 0.88],
                builder: (context, scrollController) => Material(
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
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
                      // Puxador central
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      if (provider.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: AppNotice(
                            title: 'Não foi possível concluir a busca',
                            message: provider.errorMessage!,
                            tone: AppNoticeTone.error,
                            action: TextButton(
                              onPressed: _retrySearch,
                              child: const Text('Tentar novamente'),
                            ),
                          ),
                        ),

                      // RENDERIZAÇÃO CONDICIONAL: MODO BUSCA vs DISCOVERY HUB
                      if (isSearching)
                        _buildSearchResultsView(context, isDark, provider, results)
                      else
                        _buildDiscoveryHubView(context, isDark, authProvider, vehicle, results),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4b. BOTÃO FLUTUANTE BÚSSOLA (RESTAURA O NORTE QUANDO O MAPA É GIRADO)
          if (_mapRotation.abs() > 2.0)
            Positioned(
              right: _kMapFloatingPadding,
              bottom: ((MediaQuery.sizeOf(context).height - (topInset + 76)) * _sheetExtent) + 68,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _sheetExtent > 0.78 ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: _sheetExtent > 0.78,
                  child: Material(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                    color: Theme.of(context).colorScheme.surface,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: Tooltip(
                      message: 'Redefinir para o Norte',
                      child: InkWell(
                        onTap: () {
                          _mapController.rotate(0);
                          setState(() => _mapRotation = 0.0);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
                              width: 1.2,
                            ),
                          ),
                          child: Transform.rotate(
                            angle: -_mapRotation * (math.pi / 180),
                            child: Icon(
                              Icons.explore_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. BOTÃO FLUTUANTE MINHA LOCALIZAÇÃO NO CANTO INFERIOR DIREITO DO MAPA
          Positioned(
            right: _kMapFloatingPadding,
            bottom: ((MediaQuery.sizeOf(context).height - (topInset + 76)) * _sheetExtent) + 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _sheetExtent > 0.78 ? 0.0 : 1.0,
              child: IgnorePointer(
                ignoring: _sheetExtent > 0.78,
                child: Material(
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                  color: Theme.of(context).colorScheme.surface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: Tooltip(
                    message: 'Minha localização',
                    child: InkWell(
                      onTap: _searchNearby,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
                            width: 1.2,
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

  /// Visão 1: DISCOVERY HUB (Tela Inicial Limpa, Ações Rápidas, Categorias & Destaques)
  Widget _buildDiscoveryHubView(
    BuildContext context,
    bool isDark,
    AuthProvider authProvider,
    dynamic vehicle,
    List<Workshop> results,
  ) {
    final displayName = authProvider.isAuthenticated
        ? authProvider.displayName
        : 'Motorista';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho de Boas-Vindas & Status do Veículo
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $displayName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'O que seu veículo precisa hoje?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slateMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (vehicle != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => MainShellNavigation.switchToTab(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.shortName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Barra de 3 Ações Rápidas (SOS, Orçamentos, Garagem)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Ação 1: SOS
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.crimsonSos,
                  bgColor: AppColors.crimsonSos.withValues(alpha: 0.10),
                  title: 'Auto Socorro',
                  subtitle: 'SOS 24h & Guincho',
                  onTap: _openEmergencyModal,
                ),
              ),
              const SizedBox(width: 10),
              // Ação 2: Cotações
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.chat_outlined,
                  iconColor: AppColors.emeraldDeep,
                  bgColor: AppColors.emeraldDeep.withValues(alpha: 0.10),
                  title: 'Orçamentos',
                  subtitle: 'Via WhatsApp',
                  onTap: _openQuotes,
                ),
              ),
              const SizedBox(width: 10),
              // Ação 3: Garagem
              Expanded(
                child: _buildQuickActionCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.directions_car_filled_rounded,
                  iconColor: isDark
                      ? const Color(0xFF60A5FA)
                      : Theme.of(context).colorScheme.primary,
                  bgColor: (isDark
                          ? const Color(0xFF60A5FA)
                          : Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.12),
                  title: 'Minha Garagem',
                  subtitle: 'Revisões & Km',
                  onTap: () => MainShellNavigation.switchToTab(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Categorias Automotivas (Scroll Horizontal)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'CATEGORIAS DE SERVIÇOS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.slateMuted,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.mechanic,
                label: 'Mecânica',
                icon: Icons.build_rounded,
              ),
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.oilChange,
                label: 'Troca de Óleo',
                icon: Icons.opacity_rounded,
              ),
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.autoCenter,
                label: 'Auto Center',
                icon: Icons.car_repair_rounded,
              ),
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.tireShop,
                label: 'Pneus',
                icon: Icons.tire_repair_rounded,
              ),
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.carWash,
                label: 'Lava-Jato',
                icon: Icons.local_car_wash_rounded,
              ),
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.bodyPaint,
                label: 'Funilaria',
                icon: Icons.format_paint_rounded,
              ),
              _buildCategoryPill(
                context: context,
                isDark: isDark,
                category: WorkshopCategory.specialist,
                label: 'Especializada',
                icon: Icons.verified_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Oficinas em Destaque na Região
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'OFICINAS EM DESTAQUE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slateMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${results.length} perto de você',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slateMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Center(
              child: Text(
                'Mova o mapa ou busque uma cidade para carregar oficinas.',
                style: TextStyle(color: AppColors.slateMuted, fontSize: 13),
              ),
            ),
          )
        else
          ...results.take(6).map((w) => WorkshopListTile(workshop: w)),

        // Atalho para cadastrar oficina parceira
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: OutlinedButton.icon(
            onPressed: _openWorkshopRegistration,
            icon: const Icon(Icons.add_business_rounded, size: 18),
            label: const Text('É dono de oficina? Cadastre seu estabelecimento'),
          ),
        ),
      ],
    );
  }

  /// Visão 2: MODO RESULTADOS DE BUSCA (Filtros Ativos, Contagem e Lista Completa)
  Widget _buildSearchResultsView(
    BuildContext context,
    bool isDark,
    WorkshopProvider provider,
    List<Workshop> results,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra Superior de Filtros Ativos
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (provider.selectedCategory != null)
                      Chip(
                        avatar: Icon(
                          provider.selectedCategory!.icon,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(provider.selectedCategory!.label),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () => provider.setSelectedCategory(null),
                      ),
                    if (provider.searchQuery.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.search_rounded, size: 16),
                        label: Text('"${provider.searchQuery}"'),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          _cityController.clear();
                          provider.setSearchQuery('');
                        },
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Voltar ao início',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),

        // Contador de Resultados
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Text(
            '${results.length} oficina(s) encontrada(s)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slateMuted,
            ),
          ),
        ),

        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    size: 46,
                    color: isDark ? Colors.white38 : AppColors.slateMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.searchQuery.isNotEmpty
                        ? 'Nenhuma oficina encontrada para "${provider.searchQuery}" nesta região.'
                        : 'Nenhuma oficina encontrada nesta categoria ou região.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Essa oficina ainda não está mapeada no aplicativo?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.slateMuted),
                  ),
                  const SizedBox(height: 16),
                  if (provider.searchQuery.isNotEmpty) ...[
                    FilledButton.icon(
                      onPressed: () => _openWorkshopRegistration(
                        prefilledName: provider.searchQuery,
                      ),
                      icon: const Icon(Icons.add_business_rounded, size: 18),
                      label: Text('Cadastrar "${provider.searchQuery}"'),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpar filtros e ver todas'),
                  ),
                ],
              ),
            ),
          )
        else
          ...results.map((w) => WorkshopListTile(workshop: w)),
      ],
    );
  }

  /// Componente: Card de Ação Rápida no Hub Inicial
  Widget _buildQuickActionCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.slateBorder,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.slateMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Componente: Pílula de Categoria Automotiva com Ícone
  Widget _buildCategoryPill({
    required BuildContext context,
    required bool isDark,
    required WorkshopCategory category,
    required String label,
    required IconData icon,
  }) {
    final provider = context.watch<WorkshopProvider>();
    final isSelected = provider.selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : (isDark ? AppColors.darkCard : Colors.white),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? AppColors.darkBorder : AppColors.slateBorder),
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: () => provider.setSelectedCategory(category),
          child: Container(
            width: 86,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : AppColors.slateInk),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.slateInk),
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
