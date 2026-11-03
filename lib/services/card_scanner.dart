import 'package:image_picker/image_picker.dart';

import 'card_type_detector.dart';
import 'card_validator.dart';
// ML Kit only works on iOS/Android, use a stub elsewhere.
import 'ocr/text_recognition_stub.dart'
    if (dart.library.io) 'ocr/text_recognition_mlkit.dart'
    as ocr;

bool get cardScanningSupported => ocr.isSupported;

// Possible outcomes of a scan
sealed class ScanResult {
  const ScanResult();
}

class ScanCancelled extends ScanResult {
  const ScanCancelled();
}

class ScanNoNumberFound extends ScanResult {
  const ScanNoNumberFound();
}

class ScanSuccess extends ScanResult {
  const ScanSuccess(this.number);

  final String number;
}

// Takes a photo of the card and reads the number on the device
class CardScanner {
  CardScanner({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  bool get isSupported => cardScanningSupported;

  Future<ScanResult> scan(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      requestFullMetadata: false,
    );
    if (image == null) return const ScanCancelled();

    final text = await ocr.recognizeText(image.path);
    final number = CardNumberExtractor.extract(text);
    return number == null ? const ScanNoNumberFound() : ScanSuccess(number);
  }
}

// Finds the card number in the scanned text
class CardNumberExtractor {
  CardNumberExtractor._();

  // Letters OCR often mistakes for digits.
  static const _lookalikes = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0', //
    'I': '1', 'l': '1', 'i': '1', '|': '1', //
    'Z': '2', 'z': '2', 'S': '5', 's': '5', //
    'G': '6', 'b': '6', 'B': '8',
  };

  static String? extract(String text) {
    final tokens = <String?>[];
    for (final word in text.split(RegExp(r'\s+'))) {
      final cleaned = word.replaceAll(RegExp(r'[-–.,]'), '');
      if (cleaned.isEmpty) continue;
      final fixed = cleaned.split('').map((c) => _lookalikes[c] ?? c).join();
      final hasDigit = cleaned.contains(RegExp(r'\d'));
      // Words with no digits only count as a 4-char group, e.g. "llll".
      final isNumber =
          RegExp(r'^\d+$').hasMatch(fixed) && (hasDigit || cleaned.length == 4);
      tokens.add(isNumber ? fixed : null);
    }

    // Pick the best run of groups: Luhn + valid length scores highest.
    String? best;
    var bestScore = 0;
    for (var start = 0; start < tokens.length; start++) {
      var candidate = '';
      for (var end = start; end < tokens.length; end++) {
        final token = tokens[end];
        if (token == null) break;
        candidate += token;
        if (candidate.length > CardValidator.maxLength) break;
        if (candidate.length < 13) continue;

        final type = CardTypeDetector.detect(candidate);
        final validLength =
            type?.validLengths.contains(candidate.length) ?? false;
        final score =
            (CardValidator.passesLuhn(candidate) ? 2 : 0) +
            (validLength ? 1 : 0);
        if (score > bestScore) {
          best = candidate;
          bestScore = score;
        }
      }
    }
    return best;
  }
}
