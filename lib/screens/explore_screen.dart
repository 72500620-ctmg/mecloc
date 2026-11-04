import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/expandable_bottom_sheet.dart';
import '../widgets/filter_modal.dart';
import '../widgets/floating_search_bar.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/map_marker_pin.dart';
import '../widgets/vehicle_picker_modal.dart';
import '../widgets/workshop_preview_card.dart';
import 'workshop_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MapController _mapController = MapController();

  void _openFilterModal() {
    final vehicleProvider = context.read<VehicleProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterModal(activeVehicle: vehicleProvider.activeVehicle),
    );
  }

  void _openVehicleModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VehiclePickerModal(),
    );
  }

  void _recenterLocation() {
    final provider = context.read<WorkshopProvider>();
    final center = provider.searchCenter;
    if (center != null) {
      _mapController.move(center, 14.0);
    }
  }

  void _onMarkerTapped(Workshop workshop) {
    final provider = context.read<WorkshopProvider>();
    provider.setSelectedWorkshop(workshop);
    if (workshop.latitude != null && workshop.longitude != null) {
      _mapController.move(
        LatLng(workshop.latitude! - 0.005, workshop.longitude!),
        14.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workshopProvider = context.watch<WorkshopProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;

    final filteredWorkshops = workshopProvider.getFilteredWorkshops(activeVehicle);
    final center = workshopProvider.searchCenter ?? const LatLng(-23.561684, -46.655981);
    final selectedWorkshop = workshopProvider.selectedWorkshop;

    final markers = filteredWorkshops
        .where((w) => w.latitude != null && w.longitude != null)
        .map(
          (w) => Marker(
            point: LatLng(w.latitude!, w.longitude!),
            width: 52,
            height: 56,
            child: MapMarkerPin(
              workshop: w,
              isSelected: selectedWorkshop?.id == w.id,
              onTap: () => _onMarkerTapped(w),
            ),
          ),
        )
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAPA OCUPANDO TODA A TELA (Plano de fundo principal)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.5,
              onTap: (_, __) {
                if (workshopProvider.selectedWorkshop != null) {
                  workshopProvider.setSelectedWorkshop(null);
                }
              },
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
                    'OpenStreetMap',
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. BOTÕES FLUTUANTES DO MAPA (Recenter, Zoom)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 95,
            child: Column(
              children: [
                LiquidGlassIconButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Minha localização',
                  iconColor: AppColors.forest,
                  onPressed: _recenterLocation,
                ),
                const SizedBox(height: 10),
                LiquidGlassIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Aproximar mapa',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 6),
                LiquidGlassIconButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Afastar mapa',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. BARRA DE PESQUISA FLUTUANTE (No topo sobreposta ao mapa)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: FloatingSearchBar(
              onOpenFilterModal: _openFilterModal,
              onOpenVehicleModal: _openVehicleModal,
            ),
          ),

          // 4. BOTTOM SHEET PRINCIPAL EXPANSÍVEL (Estilo Uber)
          ExpandableBottomSheet(
            workshops: filteredWorkshops,
            activeVehicle: activeVehicle,
            onOpenVehicleModal: _openVehicleModal,
          ),

          // 5. PREVIEW CARD DO ESTABELECIMENTO SELECIONADO (Sobreposto quando pin é tocado)
          if (selectedWorkshop != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 140,
              child: WorkshopPreviewCard(
                workshop: selectedWorkshop,
                activeVehicle: activeVehicle,
                onTapDetail: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => WorkshopDetailScreen(workshop: selectedWorkshop),
                    ),
                  );
                },
                onClose: () => workshopProvider.setSelectedWorkshop(null),
              ),
            ),
        ],
      ),
    );
  }
}

