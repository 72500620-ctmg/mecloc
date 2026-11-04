import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a escolha de tema (claro/escuro/sistema) do usuário.
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key);
    _mode = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  /// Alterna a partir do brilho que está na tela agora.
  Future<void> toggle(Brightness current) async {
    _mode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, _mode.name);
  }
}
