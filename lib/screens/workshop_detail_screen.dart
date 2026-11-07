import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/workshop.dart';
import '../providers/workshop_provider.dart';

class WorkshopDetailScreen extends StatelessWidget {
  const WorkshopDetailScreen({super.key, required this.workshop});
  final Workshop workshop;

  Future<void> _open(BuildContext context, Uri uri) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir esta ação no dispositivo.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopProvider>();
    final saved = provider.isFavorite(workshop.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Estabelecimento'),
        actions: [
          IconButton(
            tooltip: saved ? 'Remover dos favoritos' : 'Salvar nos favoritos',
            onPressed: () => provider.toggleFavorite(workshop.id),
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: workshop.categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        workshop.category,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: workshop.categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Informações básicas
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: const Text('Endereço'),
            subtitle: Text(workshop.address),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Telefone'),
            subtitle: Text(workshop.phone?.trim().isNotEmpty == true
                ? workshop.phone!
                : 'Não informado'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Horário informado'),
            subtitle: Text(workshop.openingHours),
          ),
          const SizedBox(height: 24),

          // BOTÕES DE AÇÃO: GOOGLE MAPS E ROTAS
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8), // Azul Google
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () =>
                _open(context, Uri.parse(workshop.googleMapsUrl)),
            icon: const Icon(Icons.map_rounded, size: 20),
            label: const Text(
              'Abrir no Google Maps (Fotos e Avaliações)',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),

          if (workshop.googleMapsDirectionsUrl != null)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _open(
                  context, Uri.parse(workshop.googleMapsDirectionsUrl!)),
              icon: const Icon(Icons.directions_car_rounded, size: 20),
              label: const Text(
                'Como chegar (Traçar rota GPS)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),

          if (workshop.phone?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () =>
                  _open(context, Uri(scheme: 'tel', path: workshop.phone)),
              icon: const Icon(Icons.call, size: 20),
              label: const Text('Ligar para o estabelecimento'),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Link secundário para dados do OpenStreetMap
          if (workshop.openStreetMapUrl != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    _open(context, Uri.parse(workshop.openStreetMapUrl!)),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text(
                  'Ver cadastro bruto no OpenStreetMap',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'As informações básicas foram localizadas via OpenStreetMap. Abra no Google Maps para ver fotos recentes, notas de outros motoristas e horários atualizados.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
