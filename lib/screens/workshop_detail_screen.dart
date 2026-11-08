import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workshop.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_quote_modal.dart';
import 'workshop_registration_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final saved = provider.isFavorite(workshop.id);
    final isRegistered = workshop.isCustomRegistered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Oficina'),
        actions: [
          IconButton(
            tooltip: saved ? 'Remover dos favoritos' : 'Salvar nos favoritos',
            onPressed: () => provider.toggleFavorite(workshop.id),
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          // Header com Nome e Badges de Categoria / Registro
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workshop.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: workshop.categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(workshop.iconData, size: 14, color: workshop.categoryColor),
                        const SizedBox(width: 5),
                        Text(
                          workshop.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: workshop.categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRegistered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF107C41)),
                          SizedBox(width: 5),
                          Text(
                            'OFICINA PARCEIRA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF107C41),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public_rounded, size: 14, color: AppColors.muted),
                          SizedBox(width: 5),
                          Text(
                            'MAPA PÚBLICO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Informações de Endereço
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined),
            title: const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            subtitle: Text(workshop.address),
          ),

          // SE FOR REGISTRADA: Exibe contato verificado e detalhes do proprietário
          if (isRegistered) ...[
            if (workshop.phone?.trim().isNotEmpty == true)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366)),
                title: const Text('WhatsApp Verificado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text(workshop.phone!),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário de Atendimento', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: Text(workshop.openingHours),
            ),
            if (workshop.description != null && workshop.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diferenciais da Oficina', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(workshop.description!, style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // BOTÃO PRINCIPAL: PEDIR ORÇAMENTO VIA WHATSAPP (APENAS REGISTRADAS)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => WhatsAppQuoteModal.show(context, workshop: workshop),
              icon: const Icon(Icons.chat_bubble_rounded, size: 20),
              label: const Text(
                'Pedir Orçamento via WhatsApp',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _open(context, Uri.parse(workshop.googleMapsUrl)),
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text(
                'Ver no Google Maps',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ] else ...[
            // SE NÃO FOR REGISTRADA: NÃO exibe "Telefone: Não informado", exibe card transparente
            if (workshop.openingHours != 'Horário não informado')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Horário informado'),
                subtitle: Text(workshop.openingHours),
              ),
            const SizedBox(height: 10),

            // Card informativo de transparência
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF2F6FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Estabelecimento do Mapa Aberto',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Esta oficina ainda não possui cadastro ou atendimento direto integrado ao MecLoc. Para consultar telefone atualizado, fotos e avaliações públicas de clientes, acesse o perfil no Google Maps.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BOTÃO PRINCIPAL: ABRIR NO GOOGLE MAPS
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8), // Azul Google
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _open(context, Uri.parse(workshop.googleMapsUrl)),
              icon: const Icon(Icons.map_rounded, size: 20),
              label: const Text(
                'Ver telefone e avaliações no Google Maps',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),

            if (workshop.googleMapsDirectionsUrl != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _open(context, Uri.parse(workshop.googleMapsDirectionsUrl!)),
                icon: const Icon(Icons.directions_car_rounded, size: 20),
                label: const Text(
                  'Como chegar (Traçar rota GPS)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            // BANNER CONVITE PARA O PROPRIETÁRIO CADASTRAR/REIVINDICAR
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF132822) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF107C41).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: Color(0xFF107C41), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'É o dono deste estabelecimento?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF107C41),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cadastre seu WhatsApp comercial gratuitamente para receber pedidos de orçamento direto pelo MecLoc e ganhar destaque no topo das buscas.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF107C41),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WorkshopRegistrationScreen(
                            initialName: workshop.name,
                            initialAddress: workshop.address,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text(
                      'Reivindicar / Cadastrar esta Oficina',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
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
                onPressed: () => _open(context, Uri.parse(workshop.openStreetMapUrl!)),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text(
                  'Ver registro bruto no OpenStreetMap',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
