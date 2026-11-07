import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quote_request.dart';
import '../providers/quotes_provider.dart';
import '../theme/app_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _selectedTab = 0; // 0: Ativos, 1: Histórico

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quotesProvider = context.watch<QuotesProvider>();
    final allQuotes = quotesProvider.quotes;

    final activeQuotes = allQuotes.where((q) => q.status != 'completed').toList();
    final historyQuotes = allQuotes.where((q) => q.status == 'completed').toList();

    final currentList = _selectedTab == 0 ? activeQuotes : historyQuotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Atividade & Orçamentos',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text('Em andamento (${activeQuotes.length})'),
                  icon: const Icon(Icons.pending_actions_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Concluídos (${historyQuotes.length})'),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
            ),
          ),
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: isDark ? Colors.white30 : AppColors.muted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0
                                ? 'Nenhuma solicitação em andamento'
                                : 'Nenhum histórico recente',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Suas propostas, orçamentos e agendamentos de serviços aparecerão aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) {
                      final quote = currentList[index];
                      return _QuoteTile(quote: quote);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  const _QuoteTile({required this.quote});

  final QuoteRequest quote;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return AppColors.electricBlue;
      case 'approved':
      case 'completed':
        return const Color(0xFF0F9D58);
      case 'pending':
      default:
        return AppColors.amberGold;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Agendado';
      case 'approved':
        return 'Aprovado';
      case 'completed':
        return 'Concluído';
      case 'pending':
      default:
        return 'Aguardando confirmação';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quotesProvider = context.read<QuotesProvider>();
    final statusColor = _getStatusColor(quote.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.darkLine : AppColors.line,
          width: 1.2,
        ),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quote.workshopName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getStatusLabel(quote.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              quote.serviceName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  quote.vehicleName,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            if (quote.notes != null) ...[
              const SizedBox(height: 6),
              Text(
                'Obs: ${quote.notes}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.estimatedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                    Text(
                      'Prazo: ${quote.estimatedDeadline}',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
                if (quote.status == 'pending')
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => quotesProvider.updateStatus(quote.id, 'scheduled'),
                    child: const Text('Confirmar Agendamento', style: TextStyle(fontSize: 12.5)),
                  )
                else if (quote.status == 'scheduled')
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => quotesProvider.updateStatus(quote.id, 'completed'),
                    child: const Text('Finalizar', style: TextStyle(fontSize: 12.5)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

