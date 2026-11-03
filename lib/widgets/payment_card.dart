import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/card_type.dart';
import '../services/countries.dart';
import '../theme/app_theme.dart';
import 'network_logo.dart';

// Card preview, flips to the back when showBack is true
class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.numberText,
    required this.type,
    this.countryCode,
    this.cvv = '',
    this.showBack = false,
    this.footnote,
  });

  final String numberText;
  final CardType? type;
  final String? countryCode;
  final String cvv;
  final bool showBack;

  final String? footnote;

  static const aspectRatio = 1.586;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showBack ? math.pi : 0),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, _) {
          final backVisible = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: backVisible
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _CardShell(
                      type: type,
                      child: _Back(type: type, cvv: cvv),
                    ),
                  )
                : _CardShell(
                    type: type,
                    child: _Front(
                      numberText: numberText,
                      type: type,
                      countryCode: countryCode,
                      footnote: footnote,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.type, required this.child});

  final CardType? type;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = type.gradient;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[1].withValues(alpha: 0.38),
            blurRadius: 30,
            spreadRadius: -6,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _SheenPainter()),
            child,
          ],
        ),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  const _SheenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(
      Offset(w * 0.95, -h * 0.15),
      w * 0.55,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
    canvas.drawCircle(
      Offset(w * 0.05, h * 1.25),
      w * 0.6,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0, 0.55],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sheen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Front: chip, number, country and logo
class _Front extends StatelessWidget {
  const _Front({
    required this.numberText,
    required this.type,
    required this.countryCode,
    required this.footnote,
  });

  final String numberText;
  final CardType? type;
  final String? countryCode;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 340;
        final label = TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 9 * s,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
        );
        final value = TextStyle(
          color: Colors.white,
          fontSize: 13 * s,
          fontWeight: FontWeight.w600,
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(22 * s, 20 * s, 22 * s, 18 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _EmvChip(scale: s),
                  SizedBox(width: 10 * s),
                  Icon(
                    Icons.contactless_outlined,
                    color: Colors.white70,
                    size: 24 * s,
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: NetworkLogo(
                      type,
                      key: ValueKey(type),
                      height: 26 * s,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    numberText.isEmpty ? '•••• •••• •••• ••••' : numberText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * s,
                      letterSpacing: 2.2 * s,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ISSUED IN', style: label),
                        SizedBox(height: 3 * s),
                        Text(
                          countryCode == null
                              ? '—'
                              : countryLabel(countryCode!),
                          style: value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (footnote != null) ...[
                    SizedBox(width: 12 * s),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ADDED', style: label),
                        SizedBox(height: 3 * s),
                        Text(footnote!, style: value),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Back: magnetic strip and CVV
class _Back extends StatelessWidget {
  const _Back({required this.type, required this.cvv});

  final CardType? type;
  final String cvv;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 340;
        final cvvLength = type?.cvvLength ?? 3;
        final shown = cvv.isEmpty ? '•' * cvvLength : cvv;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 22 * s),
            Container(height: 42 * s, color: const Color(0xE6101010)),
            SizedBox(height: 18 * s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22 * s),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36 * s,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4 * s),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF4F4F7), Color(0xFFDADBE3)],
                        ),
                      ),
                      child: CustomPaint(painter: _SignatureStripes()),
                    ),
                  ),
                  Container(
                    height: 36 * s,
                    padding: EdgeInsets.symmetric(horizontal: 12 * s),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4 * s),
                    ),
                    child: Text(
                      shown,
                      style: TextStyle(
                        color: const Color(0xFF1C1F36),
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2 * s,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22 * s, 6 * s, 22 * s, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'CVV',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9 * s,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(22 * s, 0, 22 * s, 18 * s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Never share your security code.',
                      style: TextStyle(color: Colors.white60, fontSize: 9 * s),
                    ),
                  ),
                  NetworkLogo(type, height: 20 * s),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SignatureStripes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmvChip extends StatelessWidget {
  const _EmvChip({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40 * scale,
      height: 30 * scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7 * scale),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6E7A8),
            Color(0xFFCFAE52),
            Color(0xFFF1DE95),
            Color(0xFFB8923A),
          ],
        ),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66765A1C)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(0, h / 3), Offset(w * 0.35, h / 3), paint);
    canvas.drawLine(Offset(0, h * 2 / 3), Offset(w * 0.35, h * 2 / 3), paint);
    canvas.drawLine(Offset(w * 0.65, h / 3), Offset(w, h / 3), paint);
    canvas.drawLine(Offset(w * 0.65, h * 2 / 3), Offset(w, h * 2 / 3), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.35, h * 0.2, w * 0.65, h * 0.8),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
