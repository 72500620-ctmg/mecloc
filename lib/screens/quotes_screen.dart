import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/quote_request.dart';
import '../providers/quotes_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/whatsapp_quote_modal.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  String _selectedFilter = 'all'; // 'all', 'sent_whatsapp', 'scheduled', 'completed'

  List<QuoteRequest> _filterQuotes(List<QuoteRequest> quotes) {
    if (_selectedFilter == 'all') return quotes;
    if (_selectedFilter == 'sent_whatsapp') {
      return quotes.where((q) => q.status == 'sent_whatsapp' || q.status == 'pending').toList();
    }
    return quotes.where((q) => q.status == _selectedFilter).toList();
  }

  Future<void> _reopenWhatsApp(BuildContext context, QuoteRequest quote) async {
    final phone = quote.workshopPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta oficina não possui WhatsApp cadastrado.')),
      );
      return;
    }
    final digits = QuotesProvider.formatPhoneForWhatsApp(phone);
    final uri = Uri.parse('https://wa.me/$digits');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao abrir o WhatsApp.')),
        );
      }
    }
  }

  void _openNewQuoteModal(BuildContext context) {
    final workshopProvider = context.read<WorkshopProvider>();
    final workshops = workshopProvider.workshops;

    if (workshops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesquise e selecione uma oficina no mapa para pedir orçamento.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escolha a oficina para cotar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: workshops.take(15).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final w = workshops[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: w.categoryColor.withValues(alpha: 0.15),
                        child: Icon(w.iconData, color: w.categoryColor, size: 20),
                      ),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        w.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        WhatsAppQuoteModal.show(context, workshop: w);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quotesProvider = context.watch<QuotesProvider>();
    final quotes = _filterQuotes(quotesProvider.quotes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos & Cotações'),
        actions: [
          IconButton(
            tooltip: 'Nova Cotação',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _openNewQuoteModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner explicativo
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF162E28), const Color(0xFF10201C)]
                    : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_outlined, color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cotações Rápidas via WhatsApp',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Histórico de pedidos com veículos e serviços para você acompanhar suas manutenções.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chips de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _filterChip('all', 'Todos (${quotesProvider.quotes.length})'),
                const SizedBox(width: 8),
                _filterChip(
                  'sent_whatsapp',
                  'Enviados (${quotesProvider.quotes.where((q) => q.status == 'sent_whatsapp' || q.status == 'pending').length})',
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'scheduled',
                  'Agendados (${quotesProvider.quotes.where((q) => q.status == 'scheduled').length})',
                ),
                const SizedBox(width: 8),
                _filterChip(
                  'completed',
                  'Concluídos (${quotesProvider.quotes.where((q) => q.status == 'completed').length})',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Lista de cotações
          Expanded(
            child: quotes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhuma cotação encontrada',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Solicite orçamentos diretamente na página de qualquer oficina ou crie uma nova agora.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => _openNewQuoteModal(context),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Pedir novo orçamento'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return _QuoteCard(
                        quote: quote,
                        onReopenWhatsApp: () => _reopenWhatsApp(context, quote),
                        onUpdateStatus: (newStatus) {
                          quotesProvider.updateStatus(quote.id, newStatus);
                        },
                        onDelete: () {
                          quotesProvider.removeQuote(quote.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cotação excluída do histórico.')),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = id),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.onReopenWhatsApp,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  final QuoteRequest quote;
  final VoidCallback onReopenWhatsApp;
  final ValueChanged<String> onUpdateStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkLine : AppColors.line,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.workshopName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (quote.workshopAddress != null && quote.workshopAddress!.isNotEmpty)
                      Text(
                        quote.workshopAddress!,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Alterar status',
                initialValue: quote.status,
                onSelected: onUpdateStatus,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: quote.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        quote.statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: quote.statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16, color: quote.statusColor),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'sent_whatsapp',
                    child: Text('Enviado via WhatsApp'),
                  ),
                  const PopupMenuItem(
                    value: 'scheduled',
                    child: Text('Agendado'),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Text('Concluído'),
                  ),
                  const PopupMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelado'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Detalhes do serviço e veículo
          Row(
            children: [
              const Icon(Icons.build_rounded, size: 16, color: AppColors.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quote.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.directions_car_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quote.vehicleDetails ?? quote.vehicleName,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ),
            ],
          ),
          if (quote.notes != null && quote.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    quote.notes!,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
          if (quote.status == 'sent_whatsapp' || quote.status == 'pending') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('Oficina respondeu?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => onUpdateStatus('scheduled'),
                    child: const Text('Agendei', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => onUpdateStatus('completed'),
                    child: const Text('Concluí', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Botões de ação
          Row(
            children: [
              if (quote.workshopPhone != null && quote.workshopPhone!.trim().isNotEmpty)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onReopenWhatsApp,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: const Text(
                      'Abrir WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Text(
                    'Sem telefone cadastrado',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Excluir do histórico',
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
