import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';

class EmergencyModal extends StatelessWidget {
  const EmergencyModal({
    super.key,
    required this.onSelectCategory,
  });

  final void Function(String searchKeyword, WorkshopCategory? category) onSelectCategory;

  static Future<void> show(
    BuildContext context, {
    required void Function(String searchKeyword, WorkshopCategory? category) onSelectCategory,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencyModal(onSelectCategory: onSelectCategory),
    );
  }

  Future<void> _callPhone(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível discar para $number.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao discar para $number.')),
        );
      }
    }
  }

  void _copyLocation(BuildContext context, LatLng? coords) {
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localização não disponível no momento.')),
      );
      return;
    }
    final text = 'Preciso de socorro para o meu veículo neste local: https://maps.google.com/?q=${coords.latitude},${coords.longitude} (${coords.latitude.toStringAsFixed(5)}, ${coords.longitude.toStringAsFixed(5)})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link da sua localização copiado! Cole no WhatsApp do guincho/socorro.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final coords = provider.searchCenter;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Área de toque superior para arrastar e fechar (Drag Handle)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 80) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            // Header SOS fixo com botão fechar (X)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Socorro & Emergência',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Encontre socorro urgente para o seu veículo agora.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.6),

            // Conteúdo scrollável com fechamento por pull-down overscroll
            Flexible(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is OverscrollNotification &&
                      notification.overscroll < -18) {
                    Navigator.of(context).pop();
                    return true;
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compartilhamento de Localização GPS
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF231C1B) : const Color(0xFFFFF4F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        coords != null
                            ? 'GPS: ${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}'
                            : 'Localização do veículo',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Envie suas coordenadas exatas para o motorista do guincho ou socorrista.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _copyLocation(context, coords),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar Link de Localização para WhatsApp'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'O que aconteceu com seu carro?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            // Grid de opções de socorro
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _EmergencyOptionCard(
                  icon: Icons.rv_hookup_rounded,
                  title: 'Guincho / Reboque',
                  subtitle: 'Remoção e transporte',
                  color: Colors.orange.shade800,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectCategory('guincho', null);
                  },
                ),
                _EmergencyOptionCard(
                  icon: Icons.electric_bolt_rounded,
                  title: 'Bateria / Pane',
                  subtitle: 'Carga ou troca no local',
                  color: Colors.amber.shade900,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectCategory('bateria', WorkshopCategory.autoCenter);
                  },
                ),
                _EmergencyOptionCard(
                  icon: Icons.album_rounded,
                  title: 'Pneu Furado',
                  subtitle: 'Borracharia móvel',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectCategory('borracharia', WorkshopCategory.tireShop);
                  },
                ),
                _EmergencyOptionCard(
                  icon: Icons.car_repair_rounded,
                  title: 'Mecânica Urgente',
                  subtitle: 'Oficinas próximas',
                  color: Colors.red.shade700,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectCategory('', WorkshopCategory.mechanic);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Números Oficiais de Emergência
            const Text(
              'Serviços Públicos de Emergência',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PublicEmergencyButton(
                    label: 'SAMU 192',
                    icon: Icons.medical_services_outlined,
                    onTap: () => _callPhone(context, '192'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PublicEmergencyButton(
                    label: 'Bombeiros 193',
                    icon: Icons.local_fire_department_outlined,
                    onTap: () => _callPhone(context, '193'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PublicEmergencyButton(
                    label: 'PRF 191',
                    icon: Icons.local_police_outlined,
                    onTap: () => _callPhone(context, '191'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
],
),
),
);
  }
}

class _EmergencyOptionCard extends StatelessWidget {
  const _EmergencyOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicEmergencyButton extends StatelessWidget {
  const _PublicEmergencyButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

