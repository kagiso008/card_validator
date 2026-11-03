import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/card_type.dart';
import '../services/card_format.dart';
import '../services/card_scanner.dart';
import '../services/card_type_detector.dart';
import '../services/card_validator.dart';
import '../services/countries.dart';
import '../state/card_store.dart';
import '../state/card_store_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/network_logo.dart';
import '../widgets/payment_card.dart';

// Form for capturing a new card
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key, this.scanner});

  final CardScanner? scanner;

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryFieldKey = GlobalKey<FormFieldState<String>>();
  final _typeFieldKey = GlobalKey<FormFieldState<CardType>>();
  final _numberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _countryController = TextEditingController();
  final _cvvFocus = FocusNode();
  late final CardScanner _scanner = widget.scanner ?? CardScanner();

  CardType? _type;
  bool _typeDetected = false;
  String? _countryCode;
  bool _scanning = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Show the back of the card while typing the CVV.
    _cvvFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numberController.dispose();
    _cvvController.dispose();
    _countryController.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  // Detect the card type from the number as the user types
  void _onNumberChanged(String value) {
    final detected = CardTypeDetector.detect(value);
    setState(() {
      if (detected != null) {
        _type = detected;
        _typeDetected = true;
      } else if (_typeDetected) {
        _type = null;
        _typeDetected = false;
      }
    });
  }

  void _selectType(CardType type) {
    setState(() {
      _type = type;
      _typeDetected = false;
    });
    _typeFieldKey.currentState?.validate();
  }

  // Scan the card with the camera or gallery
  Future<void> _scan() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan a card',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Lay the card flat in good light so the number is sharp.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _SourceTile(
                icon: Icons.photo_camera_rounded,
                title: 'Take a photo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _scanning = true);
    try {
      final result = await _scanner.scan(source);
      if (!mounted) return;
      switch (result) {
        case ScanSuccess(:final number):
          _numberController.text = formatCardNumber(number);
          _onNumberChanged(number);
          showAppSnack(
            context,
            'Number scanned. Check it matches your card.',
            tone: SnackTone.success,
          );
        case ScanNoNumberFound():
          showAppSnack(
            context,
            "Couldn't find a card number. Try better light, or type it in.",
            tone: SnackTone.error,
          );
        case ScanCancelled():
          break;
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        e.code.contains('access_denied')
            ? 'Camera or photo access is off. Enable it in Settings.'
            : "Couldn't scan the card: ${e.message ?? e.code}",
        tone: SnackTone.error,
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final store = CardStoreScope.read(context);
    final code = await showCountryPickerSheet(
      context,
      title: 'Issuing country',
      selected: _countryCode,
      flagged: store.bannedCountries,
    );
    if (code == null || !mounted) return;
    setState(() {
      _countryCode = code;
      _countryController.text = countryName(code);
    });
    _countryFieldKey.currentState?.validate();
  }

  // Validate the form and save the card
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final result = await CardStoreScope.read(context).addCard(
      number: _numberController.text,
      type: _type!,
      cvv: _cvvController.text,
      issuingCountry: _countryCode!,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    final message = switch (result) {
      AddCardResult.added => null,
      AddCardResult.duplicate => 'This card has already been captured.',
      AddCardResult.bannedCountry =>
        'Cards issued in ${countryName(_countryCode!)} are not accepted.',
      AddCardResult.invalid => 'The card details are not valid.',
    };
    if (message == null) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnack(context, message, tone: SnackTone.error);
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CardStoreScope.watch(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add card'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([_numberController, _cvvController]),
              builder: (context, _) => PaymentCard(
                numberText: _numberController.text,
                type: _type,
                countryCode: _countryCode,
                cvv: _cvvController.text,
                showBack: _cvvFocus.hasFocus,
              ),
            ),
            const SizedBox(height: 24),
            _ScanBanner(
              scanning: _scanning,
              supported: _scanner.isSupported,
              onTap: _scanning || !_scanner.isSupported ? null : _scan,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Card details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Card number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card_rounded),
              ),
              style: const TextStyle(
                fontSize: 17,
                letterSpacing: 1.2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.creditCardNumber],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              inputFormatters: [CardNumberInputFormatter()],
              textInputAction: TextInputAction.next,
              onChanged: _onNumberChanged,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final error = CardValidator.validateNumber(value, _type);
                if (error != null) return error;
                if (store.isCaptured(value!)) {
                  return 'This card has already been captured';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text('Card type', style: theme.textTheme.labelLarge),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _typeDetected
                      ? const Tag(
                          'Detected',
                          color: AppColors.success,
                          icon: Icons.auto_awesome,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FormField<CardType>(
              key: _typeFieldKey,
              validator: (_) => CardValidator.validateType(_type),
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardTypePicker(selected: _type, onSelected: _selectType),
                  if (field.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        field.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _cvvController,
              focusNode: _cvvFocus,
              decoration: InputDecoration(
                labelText: 'CVV',
                prefixIcon: const Icon(Icons.lock_rounded),
                helperText: _type == null
                    ? '3 or 4 digits'
                    : '${_type!.cvvLength} digits on the '
                          '${_type == CardType.amex ? 'front' : 'back'} of the card',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              autofillHints: const [AutofillHints.creditCardSecurityCode],
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) => CardValidator.validateCvv(value, _type),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: _countryFieldKey,
              controller: _countryController,
              readOnly: true,
              onTap: _pickCountry,
              decoration: InputDecoration(
                labelText: 'Issuing country',
                prefixIcon: _countryCode == null
                    ? const Icon(Icons.public_rounded)
                    : Padding(
                        padding: const EdgeInsets.only(left: 14, right: 8),
                        child: Text(
                          countryFlag(_countryCode!),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 24,
                ),
                suffixIcon: const Icon(Icons.expand_more_rounded),
              ),
              validator: (_) => CardValidator.validateCountry(
                _countryCode,
                store.bannedCountries,
                nameOf: countryName,
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: _saving ? 'Saving…' : 'Save card',
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Your CVV is checked but never stored',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// Scan button at the top of the form
class _ScanBanner extends StatelessWidget {
  const _ScanBanner({
    required this.scanning,
    required this.supported,
    required this.onTap,
  });

  final bool scanning;

  final bool supported;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final banner = Material(
      color: scheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: supported ? AppColors.primaryGradient : null,
                  color: supported ? null : scheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: scanning
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanning ? 'Reading your card…' : 'Scan card',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supported
                          ? 'Fill in the number from a photo'
                          : 'Available in the iOS and Android apps',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (supported)
                Icon(Icons.chevron_right_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
    return supported ? banner : Opacity(opacity: 0.6, child: banner);
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: scheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

// Row of card types to choose from
class _CardTypePicker extends StatelessWidget {
  const _CardTypePicker({required this.selected, required this.onSelected});

  final CardType? selected;
  final ValueChanged<CardType> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: CardType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final type = CardType.values[i];
          final isSelected = type == selected;
          final dimmed = selected != null && !isSelected;
          return Semantics(
            button: true,
            selected: isSelected,
            label: type.displayName,
            child: Tooltip(
              message: type.displayName,
              child: GestureDetector(
                onTap: () => onSelected(type),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: dimmed ? 0.4 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isSelected ? scheme.primary : Colors.transparent,
                        width: 2.4,
                      ),
                    ),
                    child: Container(
                      width: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: type.gradient,
                        ),
                      ),
                      child: NetworkLogo(type, height: 18),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
