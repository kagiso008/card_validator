import 'package:flutter/material.dart';

import '../services/countries.dart';
import '../state/card_store_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/country_picker_sheet.dart';

// Add or remove banned countries
class BannedCountriesScreen extends StatelessWidget {
  const BannedCountriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CardStoreScope.watch(context);
    final theme = Theme.of(context);
    final codes = store.bannedCountries.toList()
      ..sort((a, b) => countryName(a).compareTo(countryName(b)));

    Future<void> addCountry() async {
      final code = await showCountryPickerSheet(
        context,
        title: 'Ban a country',
        exclude: store.bannedCountries,
      );
      if (code == null) return;
      await store.banCountry(code);
      if (context.mounted) {
        showAppSnack(context, '${countryName(code)} added to the banned list');
      }
    }

    Future<void> remove(String code) async {
      await store.unbanCountry(code);
      if (!context.mounted) return;
      showAppSnack(
        context,
        'Cards from ${countryName(code)} are now accepted',
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryLight,
          onPressed: () => store.banCountry(code),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banned countries'),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_horiz_rounded),
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => _confirmReset(context),
                child: const Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Reset to defaults'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.tile),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.danger.withValues(alpha: 0.16),
                  AppColors.danger.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(switch (codes.length) {
                        0 => 'No countries blocked',
                        1 => '1 country blocked',
                        final n => '$n countries blocked',
                      }, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        'Cards issued in these countries are rejected when captured.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (codes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 48,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cards from every country are accepted.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          for (final code in codes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      countryFlag(code),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  title: Text(
                    countryName(code),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(code),
                  trailing: IconButton(
                    tooltip: 'Allow ${countryName(code)}',
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: theme.colorScheme.onSurfaceVariant,
                    onPressed: () => remove(code),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GradientButton(
        label: 'Ban a country',
        icon: Icons.add_rounded,
        expand: false,
        onPressed: addCountry,
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final store = CardStoreScope.read(context);
    final defaults = store.defaultBannedCountries.map(countryName).toList()
      ..sort();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restart_alt_rounded, size: 32),
        title: const Text('Reset to defaults?'),
        content: Text(
          defaults.isEmpty
              ? 'This clears the list.'
              : 'The list will be reset to ${defaults.join(', ')}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.resetBannedCountries();
  }
}
