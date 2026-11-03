import 'package:card_validator/models/card_type.dart';
import 'package:card_validator/models/credit_card.dart';
import 'package:card_validator/services/banned_countries_config.dart';
import 'package:card_validator/services/card_format.dart';
import 'package:card_validator/services/card_scanner.dart';
import 'package:card_validator/services/card_type_detector.dart';
import 'package:card_validator/services/card_validator.dart';
import 'package:card_validator/services/countries.dart';
import 'package:card_validator/widgets/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardTypeDetector', () {
    const samples = {
      '4111111111111111': CardType.visa,
      '5555555555554444': CardType.mastercard,
      '2223003122003222': CardType.mastercard,
      '378282246310005': CardType.amex,
      '6011111111111117': CardType.discover,
      '6221260000000000': CardType.discover,
      '6200000000000005': CardType.unionPay,
      '30569309025904': CardType.dinersClub,
      '3530111333300000': CardType.jcb,
      '6759649826438453': CardType.maestro,
    };
    samples.forEach((number, type) {
      test('$number is ${type.displayName}', () {
        expect(CardTypeDetector.detect(number), type);
      });
    });

    test('works on partial and formatted input', () {
      expect(CardTypeDetector.detect('4'), CardType.visa);
      expect(CardTypeDetector.detect('37'), CardType.amex);
      expect(CardTypeDetector.detect('5555 5555'), CardType.mastercard);
    });

    test('returns null for unknown prefixes', () {
      expect(CardTypeDetector.detect(''), isNull);
      expect(CardTypeDetector.detect('9999'), isNull);
      expect(CardTypeDetector.detect('2'), isNull);
    });
  });

  group('CardValidator', () {
    test('Luhn', () {
      expect(CardValidator.passesLuhn('4111111111111111'), isTrue);
      expect(CardValidator.passesLuhn('4111111111111112'), isFalse);
      expect(CardValidator.passesLuhn(''), isFalse);
    });

    test('number', () {
      expect(
        CardValidator.validateNumber('4111 1111 1111 1111', CardType.visa),
        isNull,
      );
      expect(CardValidator.validateNumber('', null), isNotNull);
      expect(CardValidator.validateNumber('4111', null), contains('12 to 19'));
      expect(
        CardValidator.validateNumber('4111111111111112', null),
        contains('not valid'),
      );
      expect(
        CardValidator.validateNumber('4111111111111111', CardType.mastercard),
        contains('Visa'),
      );
      expect(
        CardValidator.validateNumber('3782822463100005', null),
        contains('15'),
      );
    });

    test('CVV length depends on card type', () {
      expect(CardValidator.validateCvv('123', CardType.visa), isNull);
      expect(CardValidator.validateCvv('1234', CardType.visa), isNotNull);
      expect(CardValidator.validateCvv('1234', CardType.amex), isNull);
      expect(CardValidator.validateCvv('123', CardType.amex), isNotNull);
      expect(CardValidator.validateCvv('12a', null), isNotNull);
      expect(CardValidator.validateCvv('', null), isNotNull);
    });

    test('country', () {
      expect(CardValidator.validateCountry('ZA', {'KP'}), isNull);
      expect(CardValidator.validateCountry(null, {}), isNotNull);
      expect(
        CardValidator.validateCountry('kp', {
          'KP',
        }, nameOf: (_) => 'North Korea'),
        'Cards issued in North Korea are not accepted',
      );
    });
  });

  test('formatCardNumber groups like the physical card', () {
    expect(formatCardNumber('4111111111111111'), '4111 1111 1111 1111');
    expect(formatCardNumber('378282246310005'), '3782 822463 10005');
    expect(formatCardNumber('30569309025904'), '3056 930902 5904');
    expect(formatCardNumber('41111'), '4111 1');
  });

  group('CardNumberExtractor', () {
    test('finds a number among other card text', () {
      const text =
          'BANK OF EXAMPLE\nDEBIT\n4111 1111 1111 1111\nVALID THRU 12/28\nJ SMITH';
      expect(CardNumberExtractor.extract(text), '4111111111111111');
    });

    test('joins groups split across lines and fixes lookalike characters', () {
      const text = '5555 5555\n5555 4444\n05/27';
      expect(CardNumberExtractor.extract(text), '5555555555554444');
      expect(
        CardNumberExtractor.extract('4111 llll 1111 IIII'),
        '4111111111111111',
      );
    });

    test('handles Amex grouping', () {
      expect(
        CardNumberExtractor.extract('AMERICAN EXPRESS\n3782 822463 10005'),
        '378282246310005',
      );
    });

    test('returns null when there is no card number', () {
      expect(CardNumberExtractor.extract('VALID THRU 12/28 J SMITH'), isNull);
      expect(CardNumberExtractor.extract(''), isNull);
    });
  });

  test('CreditCard JSON round trip and masking', () {
    final card = CreditCard(
      number: '378282246310005',
      type: CardType.amex,
      issuingCountry: 'ZA',
      capturedAt: DateTime(2026, 10, 30),
    );
    final copy = CreditCard.fromJson(card.toJson());
    expect(copy.number, card.number);
    expect(copy.type, CardType.amex);
    expect(copy.issuingCountry, 'ZA');
    expect(copy.capturedAt, card.capturedAt);
    expect(card.maskedNumber, '•••• •••• ••• 0005');
    expect(card.toJson().containsKey('cvv'), isFalse);
  });

  test('BannedCountriesConfig defaults are uppercase 2-letter codes', () {
    expect(BannedCountriesConfig.defaults, isNotEmpty);
    for (final code in BannedCountriesConfig.defaults) {
      expect(code, matches(RegExp(r'^[A-Z]{2}$')));
    }
  });

  test('country helpers', () {
    expect(countryName('za'), 'South Africa');
    expect(countryFlag('ZA'), '🇿🇦');
    expect(countryFlag('??'), '🏳️');
  });

  test('formatCapturedAt', () {
    final now = DateTime(2026, 11, 3, 18);
    expect(
      formatCapturedAt(DateTime(2026, 11, 3, 9, 5), now: now),
      'Today, 09:05',
    );
    expect(
      formatCapturedAt(DateTime(2026, 11, 2, 23, 59), now: now),
      'Yesterday, 23:59',
    );
    expect(formatCapturedAt(DateTime(2026, 1, 7), now: now), '7 Jan 2026');
  });
}
