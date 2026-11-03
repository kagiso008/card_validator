import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/card_type.dart';
import '../models/credit_card.dart';
import '../services/card_storage.dart';
import '../services/card_validator.dart';

enum AddCardResult { added, invalid, duplicate, bannedCountry }

// Holds the cards and banned countries, notifies the UI on changes
class CardStore extends ChangeNotifier {
  CardStore(this._storage, {required Set<String> defaultBannedCountries})
    : _defaultBanned = Set.unmodifiable(defaultBannedCountries);

  final CardStorage _storage;
  final Set<String> _defaultBanned;

  List<CreditCard> _cards = [];
  // Numbers captured since the app opened
  final Set<String> _sessionNumbers = {};
  Set<String> _banned = {};

  List<CreditCard> get allCards => UnmodifiableListView(_cards.reversed);

  List<CreditCard> get sessionCards => List.unmodifiable(
    _cards.reversed.where((c) => _sessionNumbers.contains(c.number)),
  );

  Set<String> get bannedCountries => UnmodifiableSetView(_banned);
  Set<String> get defaultBannedCountries => _defaultBanned;

  Future<void> load() async {
    _cards = await _storage.loadCards();
    _banned = await _storage.loadBannedCountries() ?? {..._defaultBanned};
    notifyListeners();
  }

  bool isBanned(String countryCode) =>
      _banned.contains(countryCode.toUpperCase());

  bool isCaptured(String number) {
    final digits = CardValidator.digitsOnly(number);
    return _cards.any((c) => c.number == digits);
  }

  // Validates and saves a new card
  Future<AddCardResult> addCard({
    required String number,
    required CardType type,
    required String cvv,
    required String issuingCountry,
  }) async {
    final digits = CardValidator.digitsOnly(number);
    final country = issuingCountry.toUpperCase();

    // Check again here in case the form was bypassed.
    if (CardValidator.validateNumber(digits, type) != null ||
        CardValidator.validateCvv(cvv, type) != null ||
        CardValidator.validateCountry(country, const {}) != null) {
      return AddCardResult.invalid;
    }
    if (isBanned(country)) return AddCardResult.bannedCountry;
    if (isCaptured(digits)) return AddCardResult.duplicate;

    final card = CreditCard(
      number: digits,
      type: type,
      issuingCountry: country,
      capturedAt: DateTime.now(),
    );
    final updated = [..._cards, card];
    await _storage.saveCards(updated);
    _cards = updated;
    _sessionNumbers.add(digits);
    notifyListeners();
    return AddCardResult.added;
  }

  Future<void> removeCard(CreditCard card) async {
    final updated = _cards.where((c) => c.number != card.number).toList();
    await _storage.saveCards(updated);
    _cards = updated;
    _sessionNumbers.remove(card.number);
    notifyListeners();
  }

  Future<void> banCountry(String countryCode) =>
      _setBanned({..._banned, countryCode.toUpperCase()});

  Future<void> unbanCountry(String countryCode) =>
      _setBanned({..._banned}..remove(countryCode.toUpperCase()));

  // Go back to the default banned list
  Future<void> resetBannedCountries() async {
    await _storage.clearBannedCountries();
    _banned = {..._defaultBanned};
    notifyListeners();
  }

  Future<void> _setBanned(Set<String> codes) async {
    await _storage.saveBannedCountries(codes);
    _banned = codes;
    notifyListeners();
  }
}
