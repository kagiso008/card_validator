import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/banned_countries_config.dart';
import 'services/card_storage.dart';
import 'state/card_store.dart';
import 'state/card_store_scope.dart';
import 'theme/app_theme.dart';

// Load saved cards before showing the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = CardStore(
    LocalCardStorage(),
    defaultBannedCountries: BannedCountriesConfig.defaults,
  );
  await store.load();
  runApp(CardValidatorApp(store: store));
}

// Root widget, gives every screen access to the store
class CardValidatorApp extends StatelessWidget {
  const CardValidatorApp({
    super.key,
    required this.store,
    this.themeMode = ThemeMode.system,
  });

  final CardStore store;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return CardStoreScope(
      store: store,
      child: MaterialApp(
        title: 'Card Validator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        builder: (context, child) => ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child,
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
