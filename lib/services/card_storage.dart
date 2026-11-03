import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/credit_card.dart';

abstract interface class CardStorage {
  Future<List<CreditCard>> loadCards();
  Future<void> saveCards(List<CreditCard> cards);

  // Null means the user never changed the list.
  Future<Set<String>?> loadBannedCountries();
  Future<void> saveBannedCountries(Set<String> countryCodes);
  Future<void> clearBannedCountries();
}

// Cards go in secure storage, banned countries in shared preferences.
class LocalCardStorage implements CardStorage {
  LocalCardStorage({
    FlutterSecureStorage? secureStorage,
    SharedPreferencesAsync? preferences,
  }) : _secure = secureStorage ?? defaultSecureStorage,
       _prefs = preferences ?? SharedPreferencesAsync();

  // Keychain item stays on this device only
  static const defaultSecureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static const _cardsKey = 'captured_cards';
  static const _bannedKey = 'banned_countries';

  final FlutterSecureStorage _secure;
  final SharedPreferencesAsync _prefs;

  @override
  // Returns an empty list if the data can't be read
  Future<List<CreditCard>> loadCards() async {
    await _migrateUnencryptedCards();

    final String? raw;
    try {
      raw = await _secure.read(key: _cardsKey);
    } on PlatformException catch (e) {
      debugPrint('Saved cards could not be read (${e.code}).');
      return [];
    }
    if (raw == null) return [];

    final cards = _decode(raw);
    if (cards == null) {
      debugPrint('Saved cards were corrupt and have been cleared.');
      await _secure.delete(key: _cardsKey);
      return [];
    }
    return cards;
  }

  @override
  Future<void> saveCards(List<CreditCard> cards) =>
      _secure.write(key: _cardsKey, value: _encode(cards));

  @override
  Future<Set<String>?> loadBannedCountries() async =>
      (await _prefs.getStringList(_bannedKey))?.toSet();

  @override
  Future<void> saveBannedCountries(Set<String> countryCodes) =>
      _prefs.setStringList(_bannedKey, countryCodes.toList()..sort());

  @override
  Future<void> clearBannedCountries() => _prefs.remove(_bannedKey);

  // Older builds saved cards in shared preferences, move them over.
  Future<void> _migrateUnencryptedCards() async {
    final legacy = await _prefs.getString(_cardsKey);
    if (legacy == null) return;

    final existingRaw = await _secure.read(key: _cardsKey);
    final existing = existingRaw == null
        ? <CreditCard>[]
        : _decode(existingRaw) ?? [];
    final known = {for (final card in existing) card.number};
    final merged = [
      ...existing,
      ...?_decode(legacy)?.where((card) => !known.contains(card.number)),
    ];
    await _secure.write(key: _cardsKey, value: _encode(merged));
    await _prefs.remove(_cardsKey);
  }

  static String _encode(List<CreditCard> cards) =>
      jsonEncode([for (final card in cards) card.toJson()]);

  static List<CreditCard>? _decode(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          CreditCard.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return null;
    }
  }
}
