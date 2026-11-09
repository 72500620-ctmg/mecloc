import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/auth_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workshop_detail_sheet.dart';
import '../widgets/workshop_image_helper.dart';
import 'auth/login_screen.dart';
import 'workshop_registration_screen.dart';

class MyWorkshopsScreen extends StatelessWidget {
  const MyWorkshopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<WorkshopProvider>();
    final auth = context.watch<AuthProvider>();
    final isAuthenticated = auth.isAuthenticated;
    final currentUserId = auth.user?.uid;

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Minhas Oficinas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 54, color: AppColors.muted),
                const SizedBox(height: 16),
                const Text(
                  'Acesso Restrito',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Faça login para cadastrar e gerenciar suas oficinas parceiras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Fazer Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final myWorkshops = provider.customWorkshops
        .where((w) => w.ownerId == currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Oficinas Cadastradas'),
        actions: [
          IconButton(
            tooltip: 'Cadastrar nova oficina',
            icon: const Icon(Icons.add_business_rounded, color: AppColors.forest),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const WorkshopRegistrationScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: myWorkshops.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.forest.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 44,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nenhuma oficina cadastrada',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cadastre seu estabelecimento para receber cotações no WhatsApp e aparecer com destaque verificado no mapa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF107C41),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(220, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const WorkshopRegistrationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('Cadastrar Minha Oficina', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: myWorkshops.length,
              itemBuilder: (context, index) {
                final w = myWorkshops[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? AppColors.darkLine : AppColors.line,
                      width: 1.2,
                    ),
                  ),
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => WorkshopDetailSheet.show(context, w),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagem ou Ícone
                              WorkshopImageHelper.buildImage(
                                imageUrl: w.imageUrl,
                                width: 56,
                                height: 56,
                                borderRadius: BorderRadius.circular(16),
                                placeholder: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: w.categoryColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(w.iconData, color: w.categoryColor, size: 28),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            w.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF107C41).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'PARCEIRA',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF107C41),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      w.category,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: w.categoryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      w.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // Barra de Ações Rápidas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => WorkshopRegistrationScreen(
                                        workshopToEdit: w,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.forest),
                                label: const Text('Personalizar'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () {
                                  _showDeleteDialog(context, provider, w);
                                },
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.coralRed),
                                label: const Text('Excluir', style: TextStyle(color: AppColors.coralRed)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, WorkshopProvider provider, Workshop w) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Oficina?'),
        content: Text('Tem certeza de que deseja remover o cadastro da oficina "${w.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coralRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.removeCustomWorkshop(w.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oficina removida com sucesso.')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

