import 'package:card_validator/main.dart';
import 'package:card_validator/models/card_type.dart';
import 'package:card_validator/services/card_storage.dart';
import 'package:card_validator/state/card_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_card_storage.dart';

void main() {
  late CardStore store;

  setUp(() async {
    store = CardStore(
      InMemoryCardStorage() as CardStorage,
      defaultBannedCountries: {'KP'},
    );
    await store.load();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CardValidatorApp(store: store, themeMode: themeMode),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddCard(WidgetTester tester) async {
    await tester.tap(find.text('Add card'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> tapSave(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Save card'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
  }

  Future<void> pickCountry(WidgetTester tester, String name) async {
    await tester.ensureVisible(field('Issuing country'));
    await tester.tap(field('Issuing country'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search countries'),
      name,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, name));
    await tester.pumpAndSettle();
  }

  Future<void> addVisa() => store.addCard(
    number: '4111111111111111',
    type: CardType.visa,
    cvv: '123',
    issuingCountry: 'ZA',
  );

  testWidgets('infers the card type as the number is typed', (tester) async {
    await pumpApp(tester);
    expect(find.text('No cards captured yet'), findsOneWidget);
    await openAddCard(tester);

    await tester.enterText(field('Card number'), '378282246310005');
    await tester.pumpAndSettle();

    expect(find.text('3782 822463 10005'), findsNWidgets(2));
    expect(find.text('Detected'), findsOneWidget);
    expect(find.text('4 digits on the front of the card'), findsOneWidget);
    expect(find.text('Enter the CVV'), findsNothing);
    expect(find.text('Select the issuing country'), findsNothing);
  });

  testWidgets('captures a valid card and shows it in the wallet', (
    tester,
  ) async {
    await pumpApp(tester);
    await openAddCard(tester);

    await tester.enterText(field('Card number'), '5555555555554444');
    await tester.enterText(field('CVV'), '123');
    await pickCountry(tester, 'South Africa');
    await tapSave(tester);

    expect(find.text('Card saved to your wallet'), findsOneWidget);
    expect(find.text('•••• •••• •••• 4444'), findsOneWidget);
    expect(find.text('1 card captured this session'), findsOneWidget);
    expect(store.sessionCards.single.type, CardType.mastercard);
  });

  testWidgets('flags a banned issuing country', (tester) async {
    await pumpApp(tester);
    await openAddCard(tester);

    await tester.tap(field('Issuing country'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search countries'),
      'North Korea',
    );
    await tester.pumpAndSettle();
    expect(find.text('Not accepted'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'North Korea'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cards issued in North Korea are not accepted'),
      findsOneWidget,
    );
  });

  testWidgets('rejects an already captured card', (tester) async {
    await addVisa();
    await pumpApp(tester);
    await openAddCard(tester);

    await tester.enterText(field('Card number'), '4111111111111111');
    await tester.pump();

    expect(find.text('This card has already been captured'), findsOneWidget);
  });

  testWidgets('blocks submission without valid details', (tester) async {
    await pumpApp(tester);
    await openAddCard(tester);

    await tester.enterText(field('Card number'), '4111111111111111');
    await tester.enterText(field('CVV'), '12');
    await tapSave(tester);

    expect(find.text('Visa CVVs are 3 digits'), findsOneWidget);
    expect(find.text('Select the issuing country'), findsOneWidget);
    expect(store.allCards, isEmpty);
  });

  testWidgets('banned countries can be edited', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Banned countries'));
    await tester.pumpAndSettle();

    expect(find.text('1 country blocked'), findsOneWidget);
    await tester.tap(find.byTooltip('Allow North Korea'));
    await tester.pumpAndSettle();
    expect(find.text('No countries blocked'), findsOneWidget);
    expect(store.bannedCountries, isEmpty);

    await tester.tap(find.text('Ban a country'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search countries'),
      'Cuba',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Cuba'));
    await tester.pumpAndSettle();
    expect(store.bannedCountries, {'CU'});
  });

  testWidgets('wallet stack opens card details', (tester) async {
    await addVisa();
    await store.addCard(
      number: '378282246310005',
      type: CardType.amex,
      cvv: '1234',
      issuingCountry: 'GB',
    );
    await pumpApp(tester);

    expect(find.text('This session · 2'), findsOneWidget);
    await tester.tap(find.text('•••• •••• •••• 1111'));
    await tester.pumpAndSettle();
    expect(find.text('Remove card'), findsOneWidget);
    expect(find.text('This session'), findsOneWidget);
  });

  testWidgets('layouts fit a small screen in dark mode', (tester) async {
    await addVisa();
    await pumpApp(
      tester,
      size: const Size(320, 640),
      themeMode: ThemeMode.dark,
    );
    await openAddCard(tester);
    await tester.enterText(field('Card number'), '378282246310005');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Banned countries'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
