import 'package:flutter/material.dart';

import '../models/workshop.dart';

class MapMarkerPin extends StatelessWidget {
  const MapMarkerPin({
    super.key,
    required this.workshop,
    required this.isSelected,
    required this.onTap,
  });

  final Workshop workshop;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catColor = workshop.categoryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.22 : 1.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSelected ? 48 : 38,
              height: isSelected ? 48 : 38,
              decoration: BoxDecoration(
                color: isSelected ? catColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : catColor,
                  width: isSelected ? 3.0 : 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: catColor.withValues(alpha: isSelected ? 0.5 : 0.28),
                    blurRadius: isSelected ? 14 : 7,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  workshop.iconData,
                  size: isSelected ? 24 : 19,
                  color: isSelected ? Colors.white : catColor,
                ),
              ),
            ),
            // Triângulo inferior indicador de ponto no mapa
            CustomPaint(
              size: Size(isSelected ? 14 : 10, isSelected ? 8 : 6),
              painter: _TrianglePainter(
                color: isSelected ? catColor : Colors.white,
                borderColor: catColor,
                isSelected: isSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.color,
    required this.borderColor,
    required this.isSelected,
  });

  final Color color;
  final Color borderColor;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    if (!isSelected) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      color != oldDelegate.color || isSelected != oldDelegate.isSelected;
}

