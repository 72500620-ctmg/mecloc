import 'package:flutter/material.dart';

/// Mantém formulários e listas legíveis em janelas largas.
class AppPageBody extends StatelessWidget {
  const AppPageBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );
}
