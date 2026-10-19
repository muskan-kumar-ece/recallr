import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Official Recallr Brand Logo and Mark.
/// Renders the intelligence neural network emblem and optional wordmark.
class RecallrBrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final TextStyle? wordmarkStyle;

  const RecallrBrandLogo({
    super.key,
    this.size = 28.0,
    this.showWordmark = false,
    this.wordmarkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: RecallrColors.charcoalCard,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: RecallrColors.borderSubtle,
          width: size * 0.04,
        ),
        boxShadow: [
          BoxShadow(
            color: RecallrColors.aiElectricViolet.withAlpha(40),
            blurRadius: size * 0.35,
            spreadRadius: 0,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.65, size * 0.65),
          painter: _RecallrMarkPainter(),
        ),
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: size * 0.35),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Recall',
                style: wordmarkStyle ??
                    RecallrTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: RecallrColors.textPrimary,
                      fontSize: size * 0.65,
                    ),
              ),
              TextSpan(
                text: 'r',
                style: wordmarkStyle?.copyWith(color: RecallrColors.aiCyanHighlight) ??
                    RecallrTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: RecallrColors.aiCyanHighlight,
                      fontSize: size * 0.65,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecallrMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stem
    final stemPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [RecallrColors.aiCyanHighlight, RecallrColors.aiElectricViolet],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.3, h))
      ..style = PaintingStyle.fill;

    final stemRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w * 0.28, h),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(stemRRect, stemPaint);

    // Loop
    final loopPaint = Paint()
      ..color = RecallrColors.aiCyanHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.round;

    final loopPath = Path()
      ..moveTo(w * 0.25, w * 0.12)
      ..cubicTo(w * 0.9, w * 0.12, w * 0.9, h * 0.52, w * 0.25, h * 0.52);
    canvas.drawPath(loopPath, loopPaint);

    // Diagonal Leg
    final legPaint = Paint()
      ..color = RecallrColors.warmAmberGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.35, h * 0.48),
      Offset(w * 0.92, h * 0.92),
      legPaint,
    );

    // Accent Neural Node Dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.85, h * 0.2), w * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
