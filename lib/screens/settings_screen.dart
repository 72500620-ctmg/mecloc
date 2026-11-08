import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/app_notice.dart';
import 'quotes_screen.dart';
import 'workshop_registration_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _themeOptions = <(ThemeMode, IconData, String, String)>[
    (
      ThemeMode.system,
      Icons.brightness_auto_outlined,
      'Automático',
      'Acompanha a aparência do dispositivo.',
    ),
    (
      ThemeMode.light,
      Icons.light_mode_outlined,
      'Claro',
      'Mantém o aplicativo no tema claro.',
    ),
    (
      ThemeMode.dark,
      Icons.dark_mode_outlined,
      'Escuro',
      'Mantém o aplicativo no tema escuro.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Escolha como o MecLoc deve aparecer neste dispositivo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _themeOptions.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _ThemeOptionTile(
                    icon: _themeOptions[i].$2,
                    title: _themeOptions[i].$3,
                    subtitle: _themeOptions[i].$4,
                    selected: provider.themeMode == _themeOptions[i].$1,
                    onTap: () => provider.setThemeMode(_themeOptions[i].$1),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppNotice(
            title: 'Tema automático',
            message:
                'No modo automático, a interface acompanha a configuração de claro ou escuro do sistema.',
            tone: AppNoticeTone.info,
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 24),
          Text('Proprietários & Parceiros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Recursos para oficinas mecânicas e prestadores de serviços.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF107C41)),
              ),
              title: const Text(
                'Cadastre sua Oficina',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Receba cotações direto no WhatsApp e apareça no topo das buscas.',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WorkshopRegistrationScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('Histórico de Cotações', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.blue),
              ),
              title: const Text(
                'Meus Orçamentos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Visualize conversas e orçamentos solicitados.',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const QuotesScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'MecLoc • Versão 1.2.0\nSeu assistente automotivo inteligente',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon,
          color: selected ? colors.primary : colors.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colors.primary)
          : const SizedBox(width: 24),
      onTap: onTap,
    );
  }
}
