import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../models/vehicle.dart';
import '../widgets/mecloc_brand.dart';
import '../providers/auth_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notice.dart';
import '../widgets/emergency_modal.dart';
import '../widgets/workshop_detail_sheet.dart';
import '../widgets/workshop_list_tile.dart';
import '../widgets/workshop_pin_marker.dart';
import '../services/map_search_policy.dart';
import '../widgets/search_status.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';
import 'profile_screen.dart';
import 'quotes_screen.dart';
import 'workshop_registration_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final _cityController = TextEditingController();
  final _mapController = MapController();
  AnimationController? _mapAnimationController;
  static const _initialCenter = LatLng(-14.235, -51.9253);

  // Constantes de layout do Design System
  static const double _kMapFloatingPadding = 16.0;
  static const String _stadiaApiKey = String.fromEnvironment(
    'STADIA_MAPS_API_KEY',
    defaultValue: 'ab593839-51bf-4a1a-9195-a991991eab52',
  );
  double _sheetExtent = 0.55;
  int _sortOrder = 0;
  double _mapRotation = 0.0;

  // Busca automática inteligente ao mover o mapa
  Timer? _autoSearchDebounce;
  LatLng? _lastAutoSearchedCenter;
  double? _lastAutoSearchZoom;
  bool _zoomTooWide = false;
  int _mapSearchVersion = 0;
  bool _showSearchAreaButton = false;
  WorkshopProvider? _workshopProvider;
  bool _mapReady = false;
  bool _followDeviceLocation = true;
  LatLng? _lastFollowedCenter;
  bool _cameraUpdateScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<WorkshopProvider>();
    if (identical(provider, _workshopProvider)) return;
    _workshopProvider?.removeListener(_onLocationChanged);
    _workshopProvider = provider;
    provider.addListener(_onLocationChanged);
    _onLocationChanged();
  }

  void _onLocationChanged() {
    if (!_mapReady || !_followDeviceLocation || _cameraUpdateScheduled) return;
    final point = _followTarget();
    if (point == null || point == _lastFollowedCenter) return;
    _cameraUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraUpdateScheduled = false;
      if (!mounted || !_mapReady || !_followDeviceLocation) return;
      final latest = _followTarget();
      if (latest == null || latest == _lastFollowedCenter) return;
      _lastFollowedCenter = latest;
      _mapController.move(latest, 14.5);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  LatLng? _followTarget() {
    final provider = _workshopProvider;
    if (provider == null) return null;
    if (provider.deviceLocation != null) return provider.deviceLocation;
    if (provider.searchCenter != null) return provider.searchCenter;
    if (_lastFollowedCenter != null) return null;
    for (final workshop in provider.getFilteredWorkshops(null)) {
      if (workshop.latitude != null && workshop.longitude != null) {
        return LatLng(workshop.latitude!, workshop.longitude!);
      }
    }
    return null;
  }

  @override
  void dispose() {
    _mapAnimationController?.dispose();
    _workshopProvider?.removeListener(_onLocationChanged);
    _autoSearchDebounce?.cancel();
    _cityController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCameraMoved(LatLng newCenter, double newZoom) {
    _mapSearchVersion++;
    _followDeviceLocation = false;
    _autoSearchDebounce?.cancel();
    final provider = context.read<WorkshopProvider>();
    provider.cancelAutomaticSearch();
    if (_zoomTooWide != (newZoom < MapSearchPolicy.minimumZoom)) {
      setState(() => _zoomTooWide = newZoom < MapSearchPolicy.minimumZoom);
    }
    final searchCenter = context.read<WorkshopProvider>().searchCenter;
    final reference = _lastAutoSearchedCenter ?? searchCenter;
    final b = _mapController.camera.visibleBounds;
    final shouldSearch = MapSearchPolicy.shouldSearch(newCenter, newZoom,
            (south: b.south, west: b.west, north: b.north, east: b.east),
            previousCenter: reference, previousZoom: _lastAutoSearchZoom) ||
        (provider.automaticRetryAt != null &&
            newZoom >= MapSearchPolicy.minimumZoom);
    if (shouldSearch) {
      if (!_showSearchAreaButton) setState(() => _showSearchAreaButton = true);
      _autoSearchDebounce = Timer(MapSearchPolicy.debounce, () {
        if (mounted) _triggerSearchInCurrentArea(automatic: true);
      });
    }
  }

  Future<void> _triggerSearchInCurrentArea({bool automatic = false}) async {
    final version = ++_mapSearchVersion;
    _autoSearchDebounce?.cancel();
    _followDeviceLocation = false;
    if (_showSearchAreaButton) {
      setState(() => _showSearchAreaButton = false);
    }
    final center = _mapController.camera.center;
    final zoom = _mapController.camera.zoom;
    final bounds = _mapController.camera.visibleBounds;
    if (automatic && zoom < MapSearchPolicy.minimumZoom) return;

    _lastAutoSearchedCenter = center;
    _lastAutoSearchZoom = zoom;

    // Ajusta raio conforme nível de zoom para consulta rápida e focada
    final radiusMeters = zoom >= 15 ? 2000 : (zoom >= 13 ? 4000 : 8000);

    final provider = context.read<WorkshopProvider>();
    await provider.searchWorkshops(
      customCenter: center,
      automatic: automatic,
      radiusMeters: radiusMeters,
      boundingBox: (
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
      ),
    );
    if (!mounted ||
        version != _mapSearchVersion ||
        !automatic ||
        provider.automaticRetryAt == null) {
      return;
    }
    final delay = provider.automaticRetryAt!.difference(DateTime.now());
    _autoSearchDebounce =
        Timer(delay > Duration.zero ? delay : Duration.zero, () {
      if (mounted) _triggerSearchInCurrentArea(automatic: true);
    });
  }

  Future<void> _performSearch() async {
    final version = ++_mapSearchVersion;
    _autoSearchDebounce?.cancel();
    final query = _cityController.text.trim();
    if (query.isEmpty) {
      _searchNearby();
      return;
    }

    _followDeviceLocation = false;

    FocusManager.instance.primaryFocus?.unfocus();

    final provider = context.read<WorkshopProvider>();
    provider.setSearchQuery(query);

    // Correspondências locais não encerram a descoberta dos demais resultados.
    await provider.searchWorkshops(query: query);

    if (mounted &&
        version == _mapSearchVersion &&
        provider.searchCenter != null) {
      final selected = provider.selectedWorkshop;
      final target = selected?.latitude != null && selected?.longitude != null
          ? LatLng(selected!.latitude!, selected.longitude!)
          : provider.searchCenter!;
      _mapController.move(target, 14.0);
    }
  }

  Future<void> _searchNearby() async {
    _autoSearchDebounce?.cancel();
    _followDeviceLocation = true;
    _cityController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    final provider = context.read<WorkshopProvider>();
    // Se a localização do dispositivo já estiver disponível, move a câmera imediatamente sem esperar
    if (provider.deviceLocation != null) {
      _mapController.move(provider.deviceLocation!, 14.5);
    }
    await provider.searchWorkshops();
    if (mounted && _followDeviceLocation && provider.deviceLocation != null) {
      _mapController.move(provider.deviceLocation!, 14.5);
    }
  }

  Future<void> _retrySearch() => context.read<WorkshopProvider>().retrySearch();

  void _onTapWorkshopPin(Workshop w) {
    if (w.latitude == null || w.longitude == null) {
      WorkshopDetailSheet.show(context, w);
      return;
    }

    final targetLocation = LatLng(w.latitude!, w.longitude!);
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < 16.0 ? 16.2 : currentZoom;

    _animatedMapMove(
      destLocation: targetLocation,
      destZoom: targetZoom,
      onComplete: () {
        if (mounted) {
          WorkshopDetailSheet.show(context, w);
        }
      },
    );
  }

  void _animatedMapMove({
    required LatLng destLocation,
    required double destZoom,
    VoidCallback? onComplete,
  }) {
    _mapAnimationController?.stop();
    _mapAnimationController?.dispose();

    final startLocation = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;

    final latTween = Tween<double>(
      begin: startLocation.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: startLocation.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: startZoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 480),
      vsync: this,
    );
    _mapAnimationController = controller;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete?.call();
      }
    });

    controller.forward();
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
    if (_sortOrder == 1 && vehicle != null) {
      results.sort((a, b) => b
          .calculateCompatibility(vehicle)
          .percentage
          .compareTo(a.calculateCompatibility(vehicle).percentage));
    } else if (_sortOrder == 2) {
      results
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    final locatedResults = results
        .where((w) => w.latitude != null && w.longitude != null)
        .toList();
    final resultCenter = locatedResults.isEmpty
        ? null
        : LatLng(
            locatedResults.first.latitude!, locatedResults.first.longitude!);
    final center = provider.deviceLocation ??
        provider.searchCenter ??
        resultCenter ??
        _initialCenter;
    final hasKnownCenter = provider.deviceLocation != null ||
        provider.searchCenter != null ||
        resultCenter != null;

    final markers = results
        .where((w) => w.latitude != null && w.longitude != null)
        .map((w) => Marker(
              point: LatLng(w.latitude!, w.longitude!),
              width: w.isCustomRegistered ? 56 : 50,
              height: w.isCustomRegistered ? 62 : 54,
              rotate: true,
              child: WorkshopPinMarker(
                workshop: w,
                onTap: () => _onTapWorkshopPin(w),
              ),
            ))
        .toList();

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 840;
      final panelHeight = isDesktop
          ? 0.0
          : (constraints.maxHeight - topInset - 126) * _sheetExtent;
      final mapLeft = isDesktop ? 408.0 : 0.0;
      return Scaffold(
        body: Stack(
          children: [
            // 1. MAPA INTERATIVO (OpenStreetMap)
            Positioned.fill(
                left: mapLeft,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: hasKnownCenter ? 13 : 3,
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
                      _mapReady = true;
                      final current =
                          provider.deviceLocation ?? provider.searchCenter;
                      if (current != null) _mapController.move(current, 13);
                      _onLocationChanged();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _stadiaApiKey.isNotEmpty
                          ? (isDark
                              ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey'
                              : 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}@2x.png?api_key=$_stadiaApiKey')
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      fallbackUrl:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.mecloc',
                      maxZoom: 20,
                      tileBuilder: (_stadiaApiKey.isEmpty && isDark)
                          ? darkModeTileBuilder
                          : null,
                    ),
                    const CurrentLocationLayer(
                      style: LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          color: AppColors.cobaltPrimary,
                          child: Icon(Icons.navigation,
                              color: Colors.white, size: 12),
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
                )),

            if (!hasKnownCenter &&
                results.isEmpty &&
                constraints.maxHeight > 450)
              Positioned.fill(
                left: mapLeft,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(32, topInset + 184, 32, 16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.travel_explore_rounded,
                            size: 44,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        Text('Onde você quer buscar?',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            provider.isLoading
                                ? 'Obtendo sua localização…'
                                : 'Busque uma cidade ou use sua localização.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ]),
                    ),
                  ),
                ),
              ),

            Positioned(
              top: topInset + 12,
              left: mapLeft + 20,
              right: 20,
              child: Material(
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(children: [
                    const MecLocBrand(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        constraints.maxWidth - mapLeft < 360
                            ? 'NO SEU CAMINHO'
                            : 'OFICINAS · ROTAS · REVISÕES',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isDesktop ? 11 : 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // 2. BARRA DE PESQUISA FLUTUANTE COM LOADING CONJUGADO
            Positioned(
              top: topInset + 62,
              left: mapLeft + _kMapFloatingPadding,
              right: _kMapFloatingPadding,
              child: Material(
                elevation: 5,
                shadowColor:
                    Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                color: Theme.of(context).colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.floating),
                  side: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.slateBorder,
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
                          context
                              .read<WorkshopProvider>()
                              .setSearchQuery(value);
                        },
                        onSubmitted: (_) => _performSearch(),
                        decoration: InputDecoration(
                          filled: false,
                          hintText: 'Oficina, cidade ou serviço',
                          labelText: 'Buscar oficinas',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
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
                                  icon:
                                      const Icon(Icons.clear_rounded, size: 20),
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
                                  final isAuthenticated =
                                      auth?.isAuthenticated ?? false;
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
                                              builder: (_) =>
                                                  const ProfileScreen(),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const LoginScreen(),
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
                                                    : Icons
                                                        .person_outline_rounded,
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

            // BOTÃO FLUTUANTE: BUSCAR NESTA ÁREA (Estilo Google Maps)
            if (_showSearchAreaButton && !provider.isLoading)
              Positioned(
                left: mapLeft + _kMapFloatingPadding,
                top: topInset + 130,
                child: Material(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  shadowColor:
                      Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.slateBorder,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _triggerSearchInCurrentArea,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              size: 16, color: AppColors.cobaltPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Buscar nesta área',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 3. BOTÃO FLUTUANTE SOS NO MAPA (com margem padronizada)
            Positioned(
              right: _kMapFloatingPadding,
              top: topInset + 130,
              child: Material(
                elevation: 4,
                color: AppColors.crimsonSos,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _openEmergencyModal,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 16),
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

            if (isDesktop)
              Positioned(
                left: 16,
                top: topInset + 16,
                bottom: 16,
                width: 376,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sheet),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.outline)),
                  clipBehavior: Clip.antiAlias,
                  child: _buildPanel(context, null, provider, results,
                      authProvider, vehicle, isDark, true),
                ),
              )
            else
              Positioned.fill(
                top: topInset + 126,
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if ((_sheetExtent - notification.extent).abs() > 0.005) {
                      setState(() => _sheetExtent = notification.extent);
                    }
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.55,
                    minChildSize: 0.16,
                    maxChildSize: 0.92,
                    snap: true,
                    snapSizes: const [0.16, 0.55, 0.7, 0.92],
                    builder: (context, scrollController) => Material(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadii.sheet)),
                      clipBehavior: Clip.antiAlias,
                      child: _buildPanel(context, scrollController, provider,
                          results, authProvider, vehicle, isDark, false),
                    ),
                  ),
                ),
              ),

            // 4b. BOTÃO FLUTUANTE BÚSSOLA (RESTAURA O NORTE QUANDO O MAPA É GIRADO)
            if (_mapRotation.abs() > 2.0)
              Positioned(
                right: _kMapFloatingPadding,
                bottom: panelHeight + 68,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (!isDesktop && _sheetExtent > 0.78) ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: (!isDesktop && _sheetExtent > 0.78),
                    child: Material(
                      elevation: 4,
                      shadowColor:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
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
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.slateBorder,
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
              bottom: panelHeight + 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (!isDesktop && _sheetExtent > 0.78) ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: (!isDesktop && _sheetExtent > 0.78),
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
                        onTap: _searchNearby,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.slateBorder,
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

            // 6. MENSAGEM FLUTUANTE DE STATUS/LOADING EM CIMA DO MAPA (PRÓXIMO AO CONTAINER PRINCIPAL)
            if (provider.isLoading ||
                provider.searchNotice != null ||
                _zoomTooWide ||
                provider.automaticRetryAt != null ||
                (provider.errorMessage != null &&
                    (results.isNotEmpty || provider.lastSearchAutomatic)))
              Positioned(
                left: mapLeft + _kMapFloatingPadding,
                right: 76,
                bottom: panelHeight + 14,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: (!isDesktop && _sheetExtent > 0.78) ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: (!isDesktop && _sheetExtent > 0.78),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SearchStatus(
                        label: provider.isLoading
                            ? 'Buscando nesta região…'
                            : _zoomTooWide
                                ? 'Aproxime o mapa para buscar nesta região'
                                : provider.automaticRetryAt != null
                                    ? 'Atualização em instantes'
                                    : provider.resultsStale
                                        ? 'Dados salvos · atualização indisponível'
                                        : provider.searchNotice != null
                                            ? 'Cobertura limitada'
                                            : 'Atualização indisponível',
                        message: provider.searchNotice ??
                            provider.errorMessage ??
                            'A busca é atualizada após o mapa parar.',
                        busy: provider.isLoading,
                        onRefresh: _retrySearch,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildPanel(
      BuildContext context,
      ScrollController? scrollController,
      WorkshopProvider provider,
      List<Workshop> results,
      AuthProvider authProvider,
      Vehicle? vehicle,
      bool isDark,
      bool desktop) {
    final isSearching = _cityController.text.trim().isNotEmpty ||
        provider.selectedCategory != null ||
        provider.searchQuery.trim().isNotEmpty;
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(
        bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        if (!desktop)
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

        if (!provider.isLoading &&
            provider.errorMessage != null &&
            results.isEmpty &&
            !provider.lastSearchAutomatic)
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

        if (provider.isLoading && results.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Expanded(child: Text('Buscando oficinas na região…')),
            ]),
          ),
        // RENDERIZAÇÃO CONDICIONAL: MODO BUSCA vs DISCOVERY HUB
        if (isSearching)
          _buildSearchResultsView(context, isDark, provider, results)
        else
          _buildDiscoveryHubView(
              context, isDark, authProvider, vehicle, results),
      ],
    );
  }

  Widget _buildDiscoveryHubView(BuildContext context, bool isDark,
      AuthProvider authProvider, Vehicle? vehicle, List<Workshop> results) {
    final colors = Theme.of(context).colorScheme;
    final name = authProvider.isAuthenticated
        ? authProvider.displayName.split(' ').first
        : 'motorista';
    final loading = context.watch<WorkshopProvider>().isLoading;
    final compact = MediaQuery.sizeOf(context).height < 650;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding:
            EdgeInsets.fromLTRB(20, compact ? 12 : 20, 20, compact ? 12 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!compact)
            Text('BOA VIAGEM, ${name.toUpperCase()}',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant)),
          if (!compact) const SizedBox(height: 8),
          Text('Encontre sua oficina.',
              style: TextStyle(
                  fontSize: compact ? 24 : 28,
                  height: 1.1,
                  letterSpacing: -1.2,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface)),
          if (!compact) const SizedBox(height: 12),
          if (!compact)
            Text('Explore a região e filtre pelo serviço.',
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: colors.onSurfaceVariant)),
        ]),
      ),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Qual serviço você precisa?',
              style: Theme.of(context).textTheme.titleMedium)),
      const SizedBox(height: 12),
      _buildCategoryStrip(context),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: isDark ? colors.primaryContainer : AppColors.slateInk,
          borderRadius: BorderRadius.circular(AppRadii.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => MainShellNavigation.switchToTab(2),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Icon(Icons.directions_car_outlined,
                    color: Color(0xFF90B8FF), size: 30),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          vehicle == null
                              ? 'Seu carro, no radar'
                              : vehicle.shortName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          vehicle == null
                              ? 'Adicione um veículo à sua garagem'
                              : 'Ver garagem e próximas revisões',
                          style: const TextStyle(
                              color: Color(0xFFCAD4E2),
                              fontSize: 12,
                              height: 1.4)),
                    ])),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(
                child: Text('Oficinas na região',
                    style: Theme.of(context).textTheme.titleMedium)),
            _buildSortMenu(context),
          ])),
      if (results.isNotEmpty)
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('${results.length} opções no mapa',
                style:
                    TextStyle(fontSize: 12, color: colors.onSurfaceVariant))),
      if (results.isEmpty && !loading)
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vamos encontrar oficinas?',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text('Busque uma cidade ou explore a região pelo mapa.',
                  style:
                      TextStyle(color: colors.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: _searchNearby,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Usar minha localização')),
            ])),
      ...results.map((w) => WorkshopListTile(workshop: w)),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: OutlinedButton.icon(
              onPressed: _openQuotes,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Orçamentos'))),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: TextButton.icon(
              onPressed: _openWorkshopRegistration,
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Cadastrar minha oficina'))),
    ]);
  }

  Widget _buildCategoryStrip(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
          children: WorkshopCategory.values.map((category) {
        final selected = provider.selectedCategory == category;
        return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(category.icon,
                  size: 17,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant),
              label: Text(category.label),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => provider.setSelectedCategory(category),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ));
      }).toList()),
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    final hasVehicle = context.watch<VehicleProvider>().activeVehicle != null;
    return PopupMenuButton<int>(
      tooltip: 'Ordenar oficinas',
      initialValue: _sortOrder,
      onSelected: (value) => setState(() => _sortOrder = value),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
            value: 0,
            checked: _sortOrder == 0,
            child: const Text('Mais próximas')),
        if (hasVehicle)
          CheckedPopupMenuItem(
              value: 1,
              checked: _sortOrder == 1,
              child: const Text('Compatibilidade com meu veículo')),
        CheckedPopupMenuItem(
            value: 2,
            checked: _sortOrder == 2,
            child: const Text('Nome da oficina')),
      ],
      icon: const Icon(Icons.sort_rounded, size: 21),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
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

        _buildCategoryStrip(context),
        const SizedBox(height: 8),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                  child: Text('Resultados da busca',
                      style: Theme.of(context).textTheme.titleMedium)),
              _buildSortMenu(context),
            ])),
        // Contador de Resultados
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Text(
            '${results.length} ${results.length == 1 ? 'oficina encontrada' : 'oficinas encontradas'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slateMuted,
            ),
          ),
        ),

        if (results.isEmpty &&
            !provider.isLoading &&
            provider.errorMessage == null)
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
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Experimente outro serviço, limpe os filtros ou mova o mapa.',
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
}
