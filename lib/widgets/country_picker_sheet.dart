import 'package:flutter/material.dart';

import '../data/countries.dart';
import '../services/countries.dart';
import '../theme/app_theme.dart';
import 'common.dart';

// Bottom sheet with a searchable country list, returns the code
Future<String?> showCountryPickerSheet(
  BuildContext context, {
  required String title,
  String? selected,
  Set<String> flagged = const {},
  Set<String> exclude = const {},
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _CountryPicker(
        title: title,
        selected: selected,
        flagged: flagged,
        exclude: exclude,
        scrollController: scrollController,
      ),
    ),
  );
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({
    required this.title,
    required this.selected,
    required this.flagged,
    required this.exclude,
    required this.scrollController,
  });

  final String title;
  final String? selected;
  final Set<String> flagged;
  final Set<String> exclude;
  final ScrollController scrollController;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _query = '';

  List<MapEntry<String, String>> get _results {
    final q = _query.trim().toLowerCase();
    return countryNames.entries
        .where((e) => !widget.exclude.contains(e.key))
        .where(
          (e) =>
              q.isEmpty ||
              e.value.toLowerCase().contains(q) ||
              e.key.toLowerCase() == q,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search countries',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    'No countries match "$_query"',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final MapEntry(key: code, value: name) = results[i];
                    final isSelected = code == widget.selected;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      selected: isSelected,
                      selectedTileColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      leading: Text(
                        countryFlag(code),
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: widget.flagged.contains(code)
                          ? const Tag('Not accepted', color: AppColors.danger)
                          : isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(code),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
