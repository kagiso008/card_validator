import 'package:card_validator/models/credit_card.dart';
import 'package:card_validator/services/card_storage.dart';

class InMemoryCardStorage implements CardStorage {
  List<CreditCard> cards = [];
  Set<String>? banned;

  @override
  Future<List<CreditCard>> loadCards() async => [...cards];

  @override
  Future<void> saveCards(List<CreditCard> value) async => cards = [...value];

  @override
  Future<Set<String>?> loadBannedCountries() async => banned;

  @override
  Future<void> saveBannedCountries(Set<String> codes) async =>
      banned = {...codes};

  @override
  Future<void> clearBannedCountries() async => banned = null;
}
