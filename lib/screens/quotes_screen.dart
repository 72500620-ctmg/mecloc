import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/ui.dart';

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
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Título grande que encolhe ao rolar (padrão One UI).
          const SliverAppBar.large(title: Text('Orçamentos')),
          SliverPadding(
            padding: contentPadding(context, top: 4),
            sliver: SliverList.list(
              children: [
                Text('Suas solicitações', style: text.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Propostas demonstrativas para comparação.',
                  style: text.bodyMedium?.copyWith(color: t.muted),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < _proposals.length; i++)
                  FadeSlideIn(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProposalCard(
                        proposal: _proposals[i],
                        onChoose: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _proposals[i].confirmed = true);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.proposal, required this.onChoose});

  final _Proposal proposal;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg + 2),
        border: Border.all(
          color: proposal.confirmed ? t.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: AppSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBadge(icon: Icons.handyman_rounded, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proposal.workshop, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        proposal.service,
                        style: text.bodyMedium?.copyWith(color: t.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFFB300)),
                      Text(' ${proposal.rating}', style: text.labelLarge),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              proposal.price,
              style: text.headlineSmall?.copyWith(color: t.accentText),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: t.muted),
                const SizedBox(width: 5),
                Text(
                  'Prazo estimado: ${proposal.deadline}',
                  style: text.bodyMedium?.copyWith(color: t.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: proposal.confirmed
                    ? FilledButton.tonalIcon(
                        key: const ValueKey('confirmed'),
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Agendamento confirmado'),
                      )
                    : PressableScale(
                        key: const ValueKey('choose'),
                        child: FilledButton(
                          onPressed: onChoose,
                          child: const Text('Escolher proposta'),
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
