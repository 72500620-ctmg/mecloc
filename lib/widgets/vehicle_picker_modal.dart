import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vehicle_provider.dart';
import '../screens/vehicle_screen.dart';
import '../theme/app_theme.dart';

class VehiclePickerModal extends StatelessWidget {
  const VehiclePickerModal({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicleProvider = context.watch<VehicleProvider>();
    final vehicles = vehicleProvider.vehicles;

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
                'Selecione seu veículo ativo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Os estabelecimentos e especialidades serão adaptados para o veículo selecionado.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (vehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum veículo cadastrado ainda.',
                  style: TextStyle(color: isDark ? Colors.white60 : AppColors.muted),
                ),
              ),
            )
          else
            ...vehicles.map((v) {
              final isSelected = v.isSelected;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.forest.withValues(alpha: 0.10)
                      : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.forest : (isDark ? Colors.white10 : Colors.black12),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.forest : (isDark ? Colors.white12 : Colors.black12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.ink),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    v.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  subtitle: Text(
                    '${v.specsSummary} • ${v.plate.isNotEmpty ? v.plate : 'Sem placa'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 24)
                      : null,
                  onTap: () {
                    vehicleProvider.selectVehicle(v.id);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const VehicleScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Gerenciar / Adicionar novo veículo'),
          ),
        ],
      ),
    );
  }
}
