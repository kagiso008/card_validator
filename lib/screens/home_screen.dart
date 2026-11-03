import 'package:flutter/material.dart';

import '../models/credit_card.dart';
import '../services/card_scanner.dart';
import '../services/countries.dart';
import '../state/card_store.dart';
import '../state/card_store_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/network_logo.dart';
import '../widgets/payment_card.dart';
import 'add_card_screen.dart';
import 'banned_countries_screen.dart';

// Wallet screen with the captured cards
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllSaved = false;

  Future<void> _addCard() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddCardScreen(),
        fullscreenDialog: true,
      ),
    );
    if (added == true && mounted) {
      setState(() => _showAllSaved = false);
      showAppSnack(
        context,
        'Card saved to your wallet',
        tone: SnackTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CardStoreScope.watch(context);
    final theme = Theme.of(context);
    final session = store.sessionCards;
    final cards = _showAllSaved ? store.allCards : session;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wallet', style: theme.textTheme.displaySmall),
                          const SizedBox(height: 4),
                          Text(
                            switch (session.length) {
                              0 => 'No cards captured this session',
                              1 => '1 card captured this session',
                              final n => '$n cards captured this session',
                            },
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SoftIconButton(
                      icon: Icons.shield_outlined,
                      tooltip: 'Banned countries',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BannedCountriesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              sliver: SliverToBoxAdapter(
                child: PillToggle(
                  labels: [
                    'This session · ${session.length}',
                    'All saved · ${store.allCards.length}',
                  ],
                  selectedIndex: _showAllSaved ? 1 : 0,
                  onChanged: (i) => setState(() => _showAllSaved = i == 1),
                ),
              ),
            ),
            if (cards.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyWallet(showAllSaved: _showAllSaved),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _WalletStack(
                    key: ValueKey(_showAllSaved),
                    cards: cards,
                    sessionNumbers: {for (final c in session) c.number},
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GradientButton(
        label: 'Add card',
        icon: Icons.add_rounded,
        expand: false,
        onPressed: _addCard,
      ),
    );
  }
}

// Overlapping cards, tap one to bring it forward
class _WalletStack extends StatefulWidget {
  const _WalletStack({
    super.key,
    required this.cards,
    required this.sessionNumbers,
  });

  final List<CreditCard> cards;
  final Set<String> sessionNumbers;

  @override
  State<_WalletStack> createState() => _WalletStackState();
}

class _WalletStackState extends State<_WalletStack> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++)
          _buildCard(cards[i], isLast: i == cards.length - 1),
      ],
    );
  }

  Widget _buildCard(CreditCard card, {required bool isLast}) {
    final open = isLast || card.number == _expanded;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: open ? 1.0 : 0.26),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, factor, child) => Align(
        alignment: Alignment.topCenter,
        heightFactor: factor,
        child: child,
      ),
      child: Semantics(
        button: true,
        label: '${card.type.displayName} ending ${card.last4}',
        child: GestureDetector(
          onTap: () {
            if (open) {
              _showDetails(card);
            } else {
              setState(() => _expanded = card.number);
            }
          },
          child: PaymentCard(
            numberText: card.maskedNumber,
            type: card.type,
            countryCode: card.issuingCountry,
            footnote: formatShortDate(card.capturedAt),
          ),
        ),
      ),
    );
  }

  void _showDetails(CreditCard card) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CardDetailsSheet(
        card: card,
        capturedThisSession: widget.sessionNumbers.contains(card.number),
        store: CardStoreScope.read(context),
      ),
    );
  }
}

// Card details with a remove option
class _CardDetailsSheet extends StatelessWidget {
  const _CardDetailsSheet({
    required this.card,
    required this.capturedThisSession,
    required this.store,
  });

  final CreditCard card;
  final bool capturedThisSession;
  final CardStore store;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 32,
        ),
        title: const Text('Remove this card?'),
        content: Text(
          'The card ending in ${card.last4} will be deleted from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await store.removeCard(card);
    if (context.mounted) {
      Navigator.of(context).pop();
      showAppSnack(context, 'Card removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentCard(
            numberText: card.maskedNumber,
            type: card.type,
            countryCode: card.issuingCountry,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadii.tile),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Network', value: card.type.displayName),
                _DetailRow(label: 'Number', value: '•••• ${card.last4}'),
                _DetailRow(
                  label: 'Issuing country',
                  value: countryLabel(card.issuingCountry),
                ),
                _DetailRow(
                  label: 'Captured',
                  value: formatCapturedAt(card.capturedAt),
                  trailing: capturedThisSession
                      ? const Tag('This session', color: AppColors.success)
                      : null,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _delete(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Remove card'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
    this.last = false,
  });

  final String label;
  final String value;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// Shown when there are no cards yet
class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet({required this.showAllSaved});

  final bool showAllSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _GhostCard(
                  angle: -0.16,
                  offset: const Offset(-18, 6),
                  opacity: 0.35,
                ),
                _GhostCard(
                  angle: 0.1,
                  offset: const Offset(16, -4),
                  opacity: 0.6,
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_card_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            showAllSaved ? 'No saved cards' : 'No cards captured yet',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            cardScanningSupported
                ? 'Add a card by typing its details or scanning it with your camera.'
                : 'Add a card by typing in its details.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({
    required this.angle,
    required this.offset,
    required this.opacity,
  });

  final double angle;
  final Offset offset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 160,
            height: 160 / PaymentCard.aspectRatio,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: null.gradient,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
