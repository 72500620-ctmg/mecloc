import 'package:flutter/material.dart';
import '../models/workshop.dart';

class WorkshopPinMarker extends StatelessWidget {
  const WorkshopPinMarker({
    super.key,
    required this.workshop,
    required this.onTap,
  });

  final Workshop workshop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRegistered = workshop.isCustomRegistered;
    final pinColor = workshop.categoryColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: SizedBox(
          width: isRegistered ? 52 : 46,
          height: isRegistered ? 58 : 50,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Sombra inferior do pino
              Positioned(
                bottom: 2,
                child: Container(
                  width: 14,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Corpo do Pin (Estilo Pinpoint moderno)
              Positioned(
                top: isRegistered ? 8 : 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isRegistered ? 38 : 34,
                      height: isRegistered ? 38 : 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRegistered ? const Color(0xFFFFB300) : pinColor,
                          width: isRegistered ? 2.5 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isRegistered ? const Color(0xFFFFB300) : pinColor)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          workshop.iconData,
                          size: isRegistered ? 20 : 18,
                          color: pinColor,
                        ),
                      ),
                    ),
                    // Ponta do pino
                    CustomPaint(
                      size: const Size(10, 6),
                      painter: _PinTrianglePainter(
                        color: isRegistered ? const Color(0xFFFFB300) : pinColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Selo superior de parceiro verificado
              if (isRegistered)
                Positioned(
                  top: 0,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF107C41),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinTrianglePainter extends CustomPainter {
  _PinTrianglePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

