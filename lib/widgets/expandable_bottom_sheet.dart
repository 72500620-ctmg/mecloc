import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import 'workshop_card.dart';

class ExpandableBottomSheet extends StatelessWidget {
  const ExpandableBottomSheet({
    super.key,
    required this.workshops,
    required this.activeVehicle,
    required this.onOpenVehicleModal,
  });

  final List<Workshop> workshops;
  final Vehicle? activeVehicle;
  final VoidCallback onOpenVehicleModal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();

    final categories = [
      (cat: null, label: 'Todas', icon: Icons.grid_view_rounded),
      (cat: WorkshopCategory.mechanic, label: 'Mecânica', icon: Icons.build_rounded),
      (cat: WorkshopCategory.carWash, label: 'Lava-Jato', icon: Icons.local_car_wash_rounded),
      (cat: WorkshopCategory.oilChange, label: 'Troca de Óleo', icon: Icons.opacity_rounded),
      (cat: WorkshopCategory.tireShop, label: 'Borracharia', icon: Icons.radio_button_checked_rounded),
      (cat: WorkshopCategory.autoCenter, label: 'Auto Center', icon: Icons.garage_rounded),
      (cat: WorkshopCategory.detailing, label: 'Estética', icon: Icons.auto_awesome_rounded),
      (cat: WorkshopCategory.bodyPaint, label: 'Funilaria', icon: Icons.format_paint_rounded),
      (cat: WorkshopCategory.specialist, label: 'Especializada', icon: Icons.verified_user_rounded),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.16,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.16, 0.38, 0.88],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Saudação contextual
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeVehicle != null
                                    ? 'Cuidando do seu ${activeVehicle!.shortName}'
                                    : 'Encontre serviços para seu veículo',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${workshops.length} estabelecimentos especializados perto de você',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          if (activeVehicle != null)
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: onOpenVehicleModal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.forest.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.forest),
                                    const SizedBox(width: 4),
                                    Text(
                                      activeVehicle!.brand,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Categorias Rápidas Horizontais
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final c = categories[index];
                            final isSelected = provider.selectedCategory == c.cat;

                            return ChoiceChip(
                              showCheckmark: false,
                              avatar: Icon(
                                c.icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : AppColors.forest),
                              ),
                              label: Text(c.label),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : AppColors.ink),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.forest,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.forest
                                      : (isDark ? Colors.white10 : Colors.black12),
                                ),
                              ),
                              onSelected: (_) {
                                provider.setSelectedCategory(c.cat);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Lista de cards dos estabelecimentos
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (workshops.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark ? Colors.white38 : AppColors.muted,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhum estabelecimento encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tente remover filtros ou buscar por outra região/serviço.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              provider.setSearchQuery('');
                              provider.setSelectedCategory(null);
                              if (provider.onlyCompatibleWithVehicle) {
                                provider.toggleOnlyCompatible();
                              }
                            },
                            child: const Text('Limpar todos os filtros'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final workshop = workshops[index];
                        return WorkshopCard(
                          workshop: workshop,
                          activeVehicle: activeVehicle,
                        );
                      },
                      childCount: workshops.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
