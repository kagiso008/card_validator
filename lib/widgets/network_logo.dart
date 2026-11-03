import 'package:flutter/material.dart';

import '../models/card_type.dart';

// Card colours for each network
extension CardTypeArt on CardType? {
  List<Color> get gradient => switch (this) {
    CardType.visa => const [
      Color(0xFF2B3A9E),
      Color(0xFF1A1F71),
      Color(0xFF0B0F3D),
    ],
    CardType.mastercard => const [
      Color(0xFF3A3D4D),
      Color(0xFF1E2030),
      Color(0xFF0E0F18),
    ],
    CardType.amex => const [
      Color(0xFF5BB5E8),
      Color(0xFF2E77BC),
      Color(0xFF1B4F8A),
    ],
    CardType.discover => const [
      Color(0xFFFF9A4D),
      Color(0xFFE5571F),
      Color(0xFFB83A10),
    ],
    CardType.dinersClub => const [
      Color(0xFF5A7D95),
      Color(0xFF2F4A5E),
      Color(0xFF16242F),
    ],
    CardType.jcb => const [
      Color(0xFF2FA37A),
      Color(0xFF13735A),
      Color(0xFF0A4537),
    ],
    CardType.unionPay => const [
      Color(0xFFE53950),
      Color(0xFF9E1236),
      Color(0xFF3F0A2A),
    ],
    CardType.maestro => const [
      Color(0xFF7B8CFF),
      Color(0xFF5B4BD6),
      Color(0xFF34277F),
    ],
    null => const [Color(0xFF8E8AB8), Color(0xFF5E5A8C), Color(0xFF34315A)],
  };
}

// Network logos drawn in code
class NetworkLogo extends StatelessWidget {
  const NetworkLogo(this.type, {super.key, this.height = 24});

  final CardType? type;
  final double height;

  @override
  Widget build(BuildContext context) {
    final h = height;
    TextStyle word(double size, {FontStyle? style, double spacing = 0}) =>
        TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          fontStyle: style,
          letterSpacing: spacing,
          height: 1,
        );

    return SizedBox(
      height: h,
      child: switch (type) {
        CardType.visa => Center(
          child: Text(
            'VISA',
            style: word(h * 0.82, style: FontStyle.italic, spacing: 0.5),
          ),
        ),
        CardType.mastercard => _Circles(
          height: h,
          left: const Color(0xFFEB001B),
          right: const Color(0xFFF79E1B),
        ),
        CardType.maestro => _Circles(
          height: h,
          left: const Color(0xFF0099DF),
          right: const Color(0xFFEB001B),
        ),
        CardType.amex => Container(
          padding: EdgeInsets.symmetric(horizontal: h * 0.22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: h * 0.07),
            borderRadius: BorderRadius.circular(h * 0.12),
          ),
          child: Text('AMEX', style: word(h * 0.5, spacing: 1)),
        ),
        CardType.discover => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DISC', style: word(h * 0.55)),
            Container(
              width: h * 0.5,
              height: h * 0.5,
              margin: EdgeInsets.symmetric(horizontal: h * 0.04),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFFC371), Color(0xFFFF5F1F)],
                ),
              ),
            ),
            Text('VER', style: word(h * 0.55)),
          ],
        ),
        CardType.dinersClub => Center(
          child: Text(
            'Diners Club',
            style: word(
              h * 0.5,
              style: FontStyle.italic,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        CardType.jcb => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (letter, color) in const [
              ('J', Color(0xFF0E4C96)),
              ('C', Color(0xFFE21836)),
              ('B', Color(0xFF00A651)),
            ])
              Container(
                width: h * 0.62,
                height: h,
                margin: EdgeInsets.only(left: h * 0.05),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(h * 0.16),
                ),
                child: Text(letter, style: word(h * 0.55)),
              ),
          ],
        ),
        CardType.unionPay => Center(
          child: Text(
            'UnionPay',
            style: word(h * 0.55, style: FontStyle.italic),
          ),
        ),
        null => Icon(Icons.credit_card_rounded, color: Colors.white70, size: h),
      },
    );
  }
}

class _Circles extends StatelessWidget {
  const _Circles({
    required this.height,
    required this.left,
    required this.right,
  });

  final double height;
  final Color left;
  final Color right;

  @override
  Widget build(BuildContext context) {
    final d = height;
    return SizedBox(
      width: d * 1.62,
      height: d,
      child: Stack(
        children: [
          Positioned(left: 0, child: _dot(d, left)),
          Positioned(right: 0, child: _dot(d, right.withValues(alpha: 0.88))),
        ],
      ),
    );
  }

  Widget _dot(double d, Color c) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}
