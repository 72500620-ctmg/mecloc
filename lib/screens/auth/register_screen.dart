import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/liquid_glass.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedRole = 'driver'; // 'driver' ou 'workshop_owner'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: AppColors.coralRed,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A senha deve ter no mínimo 6 caracteres.'),
          backgroundColor: AppColors.coralRed,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem.'),
          backgroundColor: AppColors.coralRed,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, aceite os termos de uso para continuar.'),
          backgroundColor: AppColors.coralRed,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUpWithEmail(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forest,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.leaf),
              const SizedBox(width: 8),
              Text('Conta criada com sucesso! Seja bem-vindo, $name!'),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coralRed,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  authProvider.errorMessage ?? 'Falha ao registrar conta.',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle(role: _selectedRole);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.forest,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.leaf),
              const SizedBox(width: 8),
              Text('Cadastro com Google concluído! Olá, ${authProvider.displayName}!'),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.coralRed,
            content: Text(authProvider.errorMessage!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Criar nova conta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cadastre-se para conectar seus veículos aos melhores serviços',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 13.5),
                ),
                const SizedBox(height: 20),

                // Seleção de Perfil (Motorista vs Oficina)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkLine : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            Icons.directions_car_filled_rounded,
                            size: 18,
                            color: _selectedRole == 'driver' ? AppColors.forest : AppColors.muted,
                          ),
                          label: const Center(
                            child: Text(
                              'Motorista',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          selected: _selectedRole == 'driver',
                          selectedColor: AppColors.leaf.withValues(alpha: 0.25),
                          onSelected: (val) {
                            if (val) setState(() => _selectedRole = 'driver');
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color: _selectedRole == 'workshop_owner' ? AppColors.forest : AppColors.muted,
                          ),
                          label: const Center(
                            child: Text(
                              'Dono de Oficina',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          selected: _selectedRole == 'workshop_owner',
                          selectedColor: AppColors.leaf.withValues(alpha: 0.25),
                          onSelected: (val) {
                            if (val) setState(() => _selectedRole = 'workshop_owner');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                LiquidGlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha (mínimo 6 dígitos)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmar senha',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            activeColor: AppColors.forest,
                            onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                              child: Text(
                                'Concordo com os Termos de Uso e Política de Privacidade.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading ? null : _handleRegister,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : const Text('Criar conta'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Botão de Cadastro com Google
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: AppColors.forest),
                    label: const Text(
                      'Cadastrar com o Google',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já possui uma conta? ',
                      style: TextStyle(color: isDark ? Colors.white70 : AppColors.muted),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Fazer login',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
