import '../models/card_type.dart';
import 'card_validator.dart';

// A range of card number prefixes for one network
class _IinRange {
  const _IinRange(this.type, this.start, [int? end]) : end = end ?? start;

  final CardType type;
  final int start;
  final int end;

  int get prefixLength => start.toString().length;
}

class CardTypeDetector {
  CardTypeDetector._();

  // Order matters: specific ranges before broader ones.
  static const _ranges = [
    _IinRange(CardType.amex, 34),
    _IinRange(CardType.amex, 37),
    _IinRange(CardType.dinersClub, 300, 305),
    _IinRange(CardType.dinersClub, 3095),
    _IinRange(CardType.dinersClub, 36),
    _IinRange(CardType.dinersClub, 38, 39),
    _IinRange(CardType.jcb, 3528, 3589),
    _IinRange(CardType.visa, 4),
    _IinRange(CardType.mastercard, 51, 55),
    _IinRange(CardType.mastercard, 2221, 2720),
    _IinRange(CardType.discover, 6011),
    _IinRange(CardType.discover, 622126, 622925),
    _IinRange(CardType.discover, 644, 649),
    _IinRange(CardType.discover, 65),
    _IinRange(CardType.unionPay, 62),
    _IinRange(CardType.maestro, 50),
    _IinRange(CardType.maestro, 56, 58),
    _IinRange(CardType.maestro, 63),
    _IinRange(CardType.maestro, 67),
  ];

  // Works on partial numbers so the type updates while typing
  static CardType? detect(String input) {
    final digits = CardValidator.digitsOnly(input);
    for (final range in _ranges) {
      if (digits.length < range.prefixLength) continue;
      final prefix = int.parse(digits.substring(0, range.prefixLength));
      if (prefix >= range.start && prefix <= range.end) return range.type;
    }
    return null;
  }
}
