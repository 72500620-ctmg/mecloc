import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workshop_provider.dart';
import '../widgets/workshop_list_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final saved = context.watch<WorkshopProvider>().favoriteWorkshops;
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: saved.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'Suas oficinas salvas aparecem aqui. Toque no coração de uma oficina para salvá-la.',
                      textAlign: TextAlign.center)))
          : ListView(children: [
              for (final workshop in saved) WorkshopListTile(workshop: workshop)
            ]),
    );
  }
}
