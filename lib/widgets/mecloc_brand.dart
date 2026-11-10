import 'package:flutter/material.dart';

/// Marca compacta que retoma o ponto de localização do mapa.
class MecLocBrand extends StatelessWidget {
  const MecLocBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: colors.primary, borderRadius: BorderRadius.circular(11)),
        child: Icon(Icons.explore_rounded, color: colors.onPrimary, size: 23),
      ),
      if (!compact) ...[
        const SizedBox(width: 10),
        Text('MecLoc',
            style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: colors.onSurface)),
      ],
    ]);
  }
}
