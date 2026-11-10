import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/workshop_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_body.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'main_shell.dart';
import 'my_workshops_screen.dart';
import 'settings_screen.dart';
import 'vehicle_screen.dart';
import 'workshop_registration_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza de que deseja encerrar a sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coralRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                context.read<VehicleProvider>().clearSession();
                MainShellNavigation.switchToTab(0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Você saiu da sua conta.')),
                );
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final workshopProvider = context.watch<WorkshopProvider>();
    final authProvider = context.watch<AuthProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;
    final isAuthenticated = authProvider.isAuthenticated;
    final currentUserId = authProvider.user?.uid;
    final myWorkshops = isAuthenticated && currentUserId != null
        ? workshopProvider.customWorkshops
            .where((w) => w.ownerId == currentUserId)
            .toList()
        : const <Workshop>[];
    final displayName = authProvider.displayName;
    final email = authProvider.email;
    final photoUrl = authProvider.photoUrl;
    final isWorkshopOwner = authProvider.isWorkshopOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: AppPageBody(
          child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          // Card de Usuário
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkLine : AppColors.line,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.forest.withValues(alpha: 0.15),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(
                          isAuthenticated
                              ? Icons.person_rounded
                              : Icons.person_outline_rounded,
                          size: 36,
                          color: AppColors.forest,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAuthenticated ? displayName : 'Visitante',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAuthenticated
                            ? (email.isNotEmpty
                                ? email
                                : 'Autenticado via Google')
                            : 'Nenhuma conta conectada',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isAuthenticated)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.forest.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isWorkshopOwner
                                    ? 'Oficina Parceira'
                                    : 'Motorista',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                          if (isAuthenticated && activeVehicle != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.leaf.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                activeVehicle.shortName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção de Acesso / Autenticação
          const Text(
            'CONTA E ACESSO',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkLine : AppColors.line,
              ),
            ),
            child: Column(
              children: [
                if (!isAuthenticated) ...[
                  ListTile(
                    leading: const Icon(Icons.login_rounded,
                        color: AppColors.forest),
                    title: const Text('Entrar com sua conta'),
                    subtitle:
                        const Text('Acesse seus orçamentos e garagens salvas'),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_rounded,
                        color: AppColors.forest),
                    title: const Text('Criar novo cadastro'),
                    subtitle:
                        const Text('Cadastre-se como motorista ou oficina'),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.switch_account_outlined,
                        color: AppColors.forest),
                    title: const Text('Trocar de conta'),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded,
                        color: AppColors.coralRed),
                    title: const Text(
                      'Sair da conta',
                      style: TextStyle(
                          color: AppColors.coralRed,
                          fontWeight: FontWeight.w600),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => _showSignOutDialog(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção Gestão de Negócios / Oficinas Cadastradas
          const Text(
            'GESTÃO DO ESTABELECIMENTO',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkLine : AppColors.line,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_rounded,
                      color: AppColors.forest),
                  title: const Text('Minhas Oficinas'),
                  subtitle: Text(
                    !isAuthenticated
                        ? 'Faça login para ver suas oficinas'
                        : myWorkshops.isEmpty
                            ? 'Nenhuma oficina cadastrada'
                            : '${myWorkshops.length} oficina(s) cadastrada(s)',
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MyWorkshopsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_business_rounded,
                      color: AppColors.forest),
                  title: const Text('Cadastrar Nova Oficina'),
                  subtitle:
                      const Text('Ative atendimento via WhatsApp no MecLoc'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    if (!isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const WorkshopRegistrationScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção de Preferências e Aparência (Liquid Glass & Tema)
          const Text(
            'APARÊNCIA E SISTEMA',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkLine : AppColors.line,
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined,
                      color: AppColors.forest),
                  title: const Text('Tema do aplicativo'),
                  subtitle: Text(switch (themeProvider.themeMode) {
                    ThemeMode.system => 'Automático (sistema)',
                    ThemeMode.light => 'Claro',
                    ThemeMode.dark => 'Escuro',
                  }),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.directions_car_filled_rounded,
                      color: AppColors.forest),
                  title: const Text('Gerenciar Veículos'),
                  subtitle: Text(
                    !isAuthenticated
                        ? 'Faça login para cadastrar veículos'
                        : vehicleProvider.vehicles.isEmpty
                            ? 'Nenhum veículo cadastrado'
                            : '${vehicleProvider.vehicles.length} veículo(s) cadastrado(s)',
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    if (!isAuthenticated) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen()),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const VehicleScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sobre o MecLoc
          const Text(
            'INFORMAÇÕES',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: isDark ? AppColors.darkSurface : Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkLine : AppColors.line,
              ),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.info_outline_rounded, color: AppColors.forest),
                  title: Text('Sobre a Plataforma MecLoc'),
                  subtitle: Text(
                      'Versão 2.1 • Firebase Auth, Firestore & OpenStreetMap'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user_outlined,
                      color: AppColors.forest),
                  title: Text('Privacidade e Termos de Uso'),
                  subtitle: Text(
                      'Dados abertos do OpenStreetMap e dados locais protegidos'),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
