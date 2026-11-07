import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'settings_screen.dart';
import 'vehicle_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final activeVehicle = vehicleProvider.activeVehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
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
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Motorista MecLoc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'motorista@exemplo.com',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      if (activeVehicle != null)
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? AppColors.darkLine : AppColors.line),
            ),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.login_rounded, color: AppColors.forest),
                  title: const Text('Entrar com outra conta'),
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? AppColors.darkLine : AppColors.line),
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
                      '${vehicleProvider.vehicles.length} veículos cadastrados'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
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
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark ? AppColors.darkLine : AppColors.line),
            ),
            child: const Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.info_outline_rounded, color: AppColors.forest),
                  title: Text('Sobre a Plataforma MecLoc'),
                  subtitle:
                      Text('Versão 2.0 • Mobilidade e Cuidados Automotivos'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user_outlined,
                      color: AppColors.forest),
                  title: Text('Privacidade e Termos de Uso'),
                  subtitle:
                      Text('Dados abertos do OpenStreetMap e dados locais'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
