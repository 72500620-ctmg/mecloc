import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/app_notice.dart';

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
          Text(
            'A preferência fica salva neste dispositivo.',
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
