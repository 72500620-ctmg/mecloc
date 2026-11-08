import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workshop_list_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final saved = context.watch<WorkshopProvider>().favoriteWorkshops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oficinas Favoritas'),
      ),
      body: saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.crimsonSos.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.crimsonSos,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nenhum favorito ainda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suas oficinas salvas aparecem aqui. Toque no ícone de coração de qualquer oficina para salvá-la e acessá-la rapidamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white60 : AppColors.slateMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                return WorkshopListTile(workshop: saved[index]);
              },
            ),
    );
  }
}
