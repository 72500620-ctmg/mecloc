import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workshop_provider.dart';
import '../widgets/workshop_list_tile.dart';
import '../utils/search_text.dart';
import 'main_shell.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final saved = context.watch<WorkshopProvider>().favoriteWorkshops;
    final matches = saved
        .where((w) =>
            normalizeSearchText('${w.name} ${w.address} ${w.category}')
                .contains(normalizeSearchText(_query)))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Oficinas Favoritas')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: saved.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 64)
                                  .clamp(0, double.infinity)),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(24)),
                                  child: Icon(Icons.bookmarks_outlined,
                                      color: colors.primary, size: 32),
                                ),
                                const SizedBox(height: 24),
                                Text('Boas oficinas.\nSempre por perto.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 28,
                                        height: 1.15,
                                        letterSpacing: -0.9,
                                        fontWeight: FontWeight.w800,
                                        color: colors.onSurface)),
                                const SizedBox(height: 12),
                                Text(
                                    'Suas oficinas salvas aparecem aqui. Toque no coração de uma oficina para encontrá-la depois.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: colors.onSurfaceVariant)),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                    onPressed: () =>
                                        MainShellNavigation.switchToTab(0),
                                    icon: const Icon(Icons.map_outlined,
                                        size: 18),
                                    label: const Text('Explorar oficinas')),
                              ]),
                        ),
                      ))
              : ListView(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Seu caminho já conhecido.',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                                '${saved.length} ${saved.length == 1 ? 'oficina salva' : 'oficinas salvas'} para a próxima vez.',
                                style:
                                    TextStyle(color: colors.onSurfaceVariant)),
                            const SizedBox(height: 20),
                            TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: const InputDecoration(
                                  labelText: 'Buscar nos favoritos',
                                  prefixIcon: Icon(Icons.search_rounded)),
                            ),
                          ])),
                  if (matches.isEmpty)
                    Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Nenhum favorito corresponde à busca.',
                            style: TextStyle(color: colors.onSurfaceVariant))),
                  ...matches.map((w) => WorkshopListTile(workshop: w)),
                  const SizedBox(height: 24),
                ]),
        ),
      ),
    );
  }
}
