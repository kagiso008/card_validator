import 'package:card_validator/models/card_type.dart';
import 'package:card_validator/models/credit_card.dart';
import 'package:card_validator/services/card_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secure = FlutterSecureStorage();
  late SharedPreferencesAsync prefs;
  late LocalCardStorage storage;

  final visa = CreditCard(
    number: '4111111111111111',
    type: CardType.visa,
    issuingCountry: 'ZA',
    capturedAt: DateTime(2026, 11, 3),
  );
  final amex = CreditCard(
    number: '378282246310005',
    type: CardType.amex,
    issuingCountry: 'GB',
    capturedAt: DateTime(2026, 11, 3),
  );

  const visaJson =
      '[{"number":"4111111111111111","type":"visa","issuingCountry":"ZA","capturedAt":"2026-11-03T00:00:00.000"}]';

  void setUpStores({
    Map<String, String> secureValues = const {},
    Map<String, Object> prefValues = const {},
  }) {
    FlutterSecureStorage.setMockInitialValues({...secureValues});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({...prefValues});
    prefs = SharedPreferencesAsync();
    storage = LocalCardStorage(secureStorage: secure, preferences: prefs);
  }

  test(
    'cards are written to secure storage, never to shared preferences',
    () async {
      setUpStores();
      await storage.saveCards([visa]);

      expect(
        await secure.read(key: 'captured_cards'),
        contains('4111111111111111'),
      );
      expect(await prefs.getString('captured_cards'), isNull);
      expect((await storage.loadCards()).single.number, visa.number);
    },
  );

  test(
    'unencrypted cards from earlier builds are migrated and deleted',
    () async {
      setUpStores(prefValues: {'captured_cards': visaJson});

      final cards = await storage.loadCards();

      expect(cards.single.number, visa.number);
      expect(await prefs.getString('captured_cards'), isNull);
      expect(
        await secure.read(key: 'captured_cards'),
        contains('4111111111111111'),
      );
    },
  );

  test('migration merges with cards already in secure storage', () async {
    setUpStores(prefValues: {'captured_cards': visaJson});
    await secure.write(
      key: 'captured_cards',
      value:
          '[{"number":"378282246310005","type":"amex","issuingCountry":"GB","capturedAt":"2026-11-03T00:00:00.000"}]',
    );

    final cards = await storage.loadCards();

    expect(cards.map((c) => c.number), [amex.number, visa.number]);
    expect(await prefs.getString('captured_cards'), isNull);
  });

  test('corrupt data is cleared instead of crashing', () async {
    setUpStores(secureValues: {'captured_cards': 'not json'});

    expect(await storage.loadCards(), isEmpty);
    expect(await secure.read(key: 'captured_cards'), isNull);
  });

  test('banned countries stay in shared preferences', () async {
    setUpStores();
    await storage.saveBannedCountries({'KP', 'CU'});

    expect(await prefs.getStringList('banned_countries'), ['CU', 'KP']);
    expect(await storage.loadBannedCountries(), {'CU', 'KP'});
  });
}
