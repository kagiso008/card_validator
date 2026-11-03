import '../data/countries.dart';

String countryName(String code) => countryNames[code.toUpperCase()] ?? code;

// Builds the flag emoji from the country code
String countryFlag(String code) {
  final upper = code.toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(upper)) return '🏳️';
  return String.fromCharCodes(upper.codeUnits.map((c) => 0x1F1E6 + c - 65));
}

String countryLabel(String code) => '${countryFlag(code)} ${countryName(code)}';
