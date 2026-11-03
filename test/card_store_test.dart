import 'package:card_validator/models/card_type.dart';
import 'package:card_validator/models/credit_card.dart';
import 'package:card_validator/state/card_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_card_storage.dart';

void main() {
  late InMemoryCardStorage storage;
  late CardStore store;

  setUp(() async {
    storage = InMemoryCardStorage();
    store = CardStore(storage, defaultBannedCountries: {'KP', 'IR'});
    await store.load();
  });

  Future<AddCardResult> addVisa({String country = 'ZA', String cvv = '123'}) =>
      store.addCard(
        number: '4111 1111 1111 1111',
        type: CardType.visa,
        cvv: cvv,
        issuingCountry: country,
      );

  test('stores a valid card without the CVV', () async {
    expect(await addVisa(), AddCardResult.added);
    expect(storage.cards.single.number, '4111111111111111');
    expect(store.sessionCards, hasLength(1));
  });

  test('rejects duplicates', () async {
    await addVisa();
    expect(await addVisa(country: 'GB'), AddCardResult.duplicate);
    expect(storage.cards, hasLength(1));
  });

  test('rejects banned countries, case-insensitively', () async {
    expect(await addVisa(country: 'kp'), AddCardResult.bannedCountry);
    expect(storage.cards, isEmpty);
  });

  test('rejects invalid details even if the UI is bypassed', () async {
    expect(await addVisa(cvv: '12'), AddCardResult.invalid);
    expect(
      await store.addCard(
        number: '4111111111111112',
        type: CardType.visa,
        cvv: '123',
        issuingCountry: 'ZA',
      ),
      AddCardResult.invalid,
    );
    expect(storage.cards, isEmpty);
  });

  test(
    'cards from earlier sessions are saved but not in this session',
    () async {
      storage.cards = [
        CreditCard(
          number: '5555555555554444',
          type: CardType.mastercard,
          issuingCountry: 'ZA',
          capturedAt: DateTime(2026),
        ),
      ];
      await store.load();
      await addVisa();
      expect(store.allCards, hasLength(2));
      expect(store.sessionCards.single.number, '4111111111111111');
      expect(store.isCaptured('5555 5555 5555 4444'), isTrue);
    },
  );

  test('banned list is configurable and persisted', () async {
    await store.banCountry('ru');
    await store.unbanCountry('IR');
    expect(store.bannedCountries, {'KP', 'RU'});
    expect(storage.banned, {'KP', 'RU'});

    final reloaded = CardStore(storage, defaultBannedCountries: {'KP', 'IR'});
    await reloaded.load();
    expect(reloaded.bannedCountries, {'KP', 'RU'});

    await reloaded.resetBannedCountries();
    expect(reloaded.bannedCountries, {'KP', 'IR'});
    expect(storage.banned, isNull);
  });

  test('unbanned country can be captured', () async {
    await store.unbanCountry('KP');
    expect(await addVisa(country: 'KP'), AddCardResult.added);
  });
}
