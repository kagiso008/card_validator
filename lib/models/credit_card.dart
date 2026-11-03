import 'card_type.dart';

// The CVV is never stored.
class CreditCard {
  const CreditCard({
    required this.number,
    required this.type,
    required this.issuingCountry,
    required this.capturedAt,
  });

  final String number;
  final CardType type;

  final String issuingCountry;
  final DateTime capturedAt;

  String get last4 => number.substring(number.length - 4);

  // Hides everything except the last 4 digits
  String get maskedNumber {
    final hidden = number.length - 4;
    final groups = <String>[];
    for (var i = 0; i < hidden; i += 4) {
      groups.add('•' * (hidden - i < 4 ? hidden - i : 4));
    }
    return [...groups, last4].join(' ');
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'type': type.name,
    'issuingCountry': issuingCountry,
    'capturedAt': capturedAt.toIso8601String(),
  };

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
    number: json['number'] as String,
    type: CardType.values.byName(json['type'] as String),
    issuingCountry: json['issuingCountry'] as String,
    capturedAt: DateTime.parse(json['capturedAt'] as String),
  );
}
