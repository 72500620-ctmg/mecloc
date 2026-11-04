import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({
    super.key,
    required this.activeVehicle,
  });

  final Vehicle? activeVehicle;

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  WorkshopCategory? _selectedCat;
  bool _onlyCompatible = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<WorkshopProvider>();
    _selectedCat = provider.selectedCategory;
    _onlyCompatible = provider.onlyCompatibleWithVehicle;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<WorkshopProvider>();

    final categories = [
      (cat: WorkshopCategory.mechanic, label: 'Oficina Mecânica', icon: Icons.build_rounded),
      (cat: WorkshopCategory.carWash, label: 'Lava-Jato', icon: Icons.local_car_wash_rounded),
      (cat: WorkshopCategory.autoCenter, label: 'Centro Automotivo', icon: Icons.garage_rounded),
      (cat: WorkshopCategory.oilChange, label: 'Troca de Óleo', icon: Icons.opacity_rounded),
      (cat: WorkshopCategory.tireShop, label: 'Borracharia & Pneus', icon: Icons.radio_button_checked_rounded),
      (cat: WorkshopCategory.detailing, label: 'Estética Automotiva', icon: Icons.auto_awesome_rounded),
      (cat: WorkshopCategory.bodyPaint, label: 'Funilaria e Pintura', icon: Icons.format_paint_rounded),
      (cat: WorkshopCategory.specialist, label: 'Especializada em Marcas', icon: Icons.verified_user_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros inteligentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCat = null;
                    _onlyCompatible = false;
                  });
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compatibilidade com o veículo ativo
          if (widget.activeVehicle != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.forest.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: AppColors.forest,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apenas 100% Especialistas',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        Text(
                          'Filtrar oficinas especializadas no seu ${widget.activeVehicle!.shortName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _onlyCompatible,
                    activeColor: AppColors.forest,
                    onChanged: (val) => setState(() => _onlyCompatible = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'Categorias de Serviços',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((c) {
              final isSelected = _selectedCat == c.cat;
              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  c.icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.forest,
                ),
                label: Text(c.label),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.ink),
                ),
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                selectedColor: AppColors.forest,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.forest : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    _selectedCat = val ? c.cat : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                provider.setSelectedCategory(_selectedCat);
                if (_onlyCompatible != provider.onlyCompatibleWithVehicle) {
                  provider.toggleOnlyCompatible();
                }
                Navigator.pop(context);
              },
              child: const Text('Aplicar Filtros'),
            ),
          ),
        ],
      ),
    );
  }
}
