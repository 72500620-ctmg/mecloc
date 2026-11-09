import 'package:flutter/material.dart';
import '../models/workshop.dart';
import '../widgets/workshop_detail_sheet.dart';

/// Tela de compatibilidade para rotas nomeadas ou navegações existentes.
/// Carrega o [WorkshopDetailSheet] moderno de detalhes da oficina.
class WorkshopDetailScreen extends StatelessWidget {
  const WorkshopDetailScreen({super.key, required this.workshop});
  final Workshop workshop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: SafeArea(
        top: false,
        child: WorkshopDetailSheet(workshop: workshop),
      ),
    );
  }
}
