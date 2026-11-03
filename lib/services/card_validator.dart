import '../models/card_type.dart';
import 'card_type_detector.dart';

// Each validator returns an error message, or null if valid.
class CardValidator {
  CardValidator._();

  static const minLength = 12;
  static const maxLength = 19;

  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  // Luhn checksum: double every second digit from the right
  static bool passesLuhn(String digits) {
    if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) return false;
    var sum = 0;
    var doubleIt = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = digits.codeUnitAt(i) - 48;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }

  // Checks length, type match and Luhn
  static String? validateNumber(String? input, CardType? selectedType) {
    final digits = digitsOnly(input ?? '');
    if (digits.isEmpty) return 'Enter the card number';
    if (digits.length < minLength || digits.length > maxLength) {
      return 'Card numbers are $minLength to $maxLength digits';
    }
    final detected = CardTypeDetector.detect(digits);
    if (selectedType != null && detected != null && detected != selectedType) {
      return 'This looks like a ${detected.displayName} number, '
          'not ${selectedType.displayName}';
    }
    final type = selectedType ?? detected;
    if (type != null && !type.validLengths.contains(digits.length)) {
      return '${type.displayName} numbers are ${type.validLengthsLabel} digits';
    }
    if (!passesLuhn(digits)) return 'This card number is not valid';
    return null;
  }

  static String? validateType(CardType? type) =>
      type == null ? 'Select the card type' : null;

  // Amex uses 4 digits, the rest use 3
  static String? validateCvv(String? input, CardType? type) {
    final cvv = input ?? '';
    if (cvv.isEmpty) return 'Enter the CVV';
    if (!RegExp(r'^\d+$').hasMatch(cvv)) {
      return 'The CVV can only contain digits';
    }
    if (type != null) {
      if (cvv.length != type.cvvLength) {
        return '${type.displayName} CVVs are ${type.cvvLength} digits';
      }
    } else if (cvv.length < 3 || cvv.length > 4) {
      return 'The CVV is 3 or 4 digits';
    }
    return null;
  }

  static String? validateCountry(
    String? countryCode,
    Set<String> bannedCountries, {
    String Function(String code)? nameOf,
  }) {
    if (countryCode == null || countryCode.isEmpty) {
      return 'Select the issuing country';
    }
    if (bannedCountries.contains(countryCode.toUpperCase())) {
      final name = nameOf?.call(countryCode) ?? countryCode;
      return 'Cards issued in $name are not accepted';
    }
    return null;
  }
}
