import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final _proposals = <_Proposal>[
    _Proposal(
      workshop: 'Auto Center Exemplo',
      service: 'Revisão preventiva',
      price: 'A partir de R\$ 280',
      deadline: '1 dia útil',
      rating: '4,7',
    ),
    _Proposal(
      workshop: 'Mecânica do Bairro',
      service: 'Revisão preventiva',
      price: 'A partir de R\$ 320',
      deadline: '2 dias úteis',
      rating: '4,5',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orçamentos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Suas solicitações',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Propostas demonstrativas para comparação.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          for (final proposal in _proposals) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            proposal.workshop,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.star, size: 17, color: Colors.amber),
                        Text(' ${proposal.rating}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(proposal.service),
                    const SizedBox(height: 12),
                    Text(
                      proposal.price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                    Text(
                      'Prazo estimado: ${proposal.deadline}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonal(
                        onPressed: proposal.confirmed
                            ? null
                            : () => setState(() => proposal.confirmed = true),
                        child: Text(
                          proposal.confirmed
                              ? 'Agendamento confirmado'
                              : 'Escolher proposta',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Proposal {
  _Proposal({
    required this.workshop,
    required this.service,
    required this.price,
    required this.deadline,
    required this.rating,
  });

  final String workshop;
  final String service;
  final String price;
  final String deadline;
  final String rating;
  bool confirmed = false;
}
