import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mecloc/providers/theme_provider.dart';

void main() {
  test('tema começa no padrão do sistema e persiste escolhas explícitas',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();
    await provider.initialize();
    expect(provider.themeMode, ThemeMode.system);

    await provider.setThemeMode(ThemeMode.dark);
    expect(provider.themeMode, ThemeMode.dark);

    final restored = ThemeProvider();
    await restored.initialize();
    expect(restored.themeMode, ThemeMode.dark);

    await restored.setThemeMode(ThemeMode.system);
    final systemDefault = ThemeProvider();
    await systemDefault.initialize();
    expect(systemDefault.themeMode, ThemeMode.system);

    provider.dispose();
    restored.dispose();
    systemDefault.dispose();
  });
}
