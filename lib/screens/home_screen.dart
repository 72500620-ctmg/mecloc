import 'package:flutter/material.dart';

import 'main_shell.dart';

/// Ponto de entrada da HomeScreen moderna, redirecionando para o MainShell com navegação Liquid Glass
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
