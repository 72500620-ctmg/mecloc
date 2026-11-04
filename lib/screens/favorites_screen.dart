import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workshop_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workshopProvider = context.watch<WorkshopProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;

    final favoriteWorkshops = workshopProvider.workshops
        .where((w) => workshopProvider.isFavorite(w.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: favoriteWorkshops.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.coralRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 40,
                        color: AppColors.coralRed,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Nenhum favorito salvo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toque no ícone de coração em qualquer oficina para salvar e acessar rapidamente depois.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${favoriteWorkshops.length} estabelecimentos salvos',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...favoriteWorkshops.map(
                  (w) => WorkshopCard(
                    workshop: w,
                    activeVehicle: activeVehicle,
                  ),
                ),
              ],
            ),
    );
  }
}
