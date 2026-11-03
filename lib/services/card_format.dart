import 'package:flutter/services.dart';

import '../models/card_type.dart';
import 'card_type_detector.dart';
import 'card_validator.dart';

// Amex 4-6-5, Diners 4-6-4, others groups of 4.
String formatCardNumber(String input) {
  final digits = CardValidator.digitsOnly(input);
  final type = CardTypeDetector.detect(digits);
  final List<int> groups;
  if (type == CardType.amex) {
    groups = [4, 6, 5];
  } else if (type == CardType.dinersClub && digits.length <= 14) {
    groups = [4, 6, 4];
  } else {
    groups = List.filled(5, 4);
  }

  final buffer = StringBuffer();
  var index = 0;
  for (final size in groups) {
    if (index >= digits.length) break;
    if (index > 0) buffer.write(' ');
    final end = (index + size).clamp(0, digits.length);
    buffer.write(digits.substring(index, end));
    index = end;
  }
  if (index < digits.length) buffer.write(digits.substring(index));
  return buffer.toString();
}

// Adds spaces while typing and keeps the cursor in place
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = CardValidator.digitsOnly(newValue.text);
    if (digits.length > CardValidator.maxLength) {
      digits = digits.substring(0, CardValidator.maxLength);
    }
    final formatted = formatCardNumber(digits);

    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = CardValidator.digitsOnly(
      newValue.text.substring(0, cursor),
    ).length.clamp(0, digits.length);

    // Move the cursor past the same number of digits as before
    var offset = 0;
    var seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (formatted[offset] != ' ') seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
