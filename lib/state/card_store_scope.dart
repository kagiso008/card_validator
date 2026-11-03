import 'package:flutter/widgets.dart';

import 'card_store.dart';

// Shares the store with the widget tree
class CardStoreScope extends InheritedNotifier<CardStore> {
  const CardStoreScope({
    super.key,
    required CardStore store,
    required super.child,
  }) : super(notifier: store);

  // Rebuilds the widget when the store changes
  static CardStore watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardStoreScope>()!.notifier!;

  // Use in callbacks, does not rebuild
  static CardStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CardStoreScope>()!.notifier!;
}
