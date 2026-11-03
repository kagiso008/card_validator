// Card networks with their valid number lengths and CVV length
enum CardType {
  visa('Visa', [13, 16, 19], 3),
  mastercard('Mastercard', [16], 3),
  amex('American Express', [15], 4),
  discover('Discover', [16, 17, 18, 19], 3),
  dinersClub('Diners Club', [14, 15, 16, 17, 18, 19], 3),
  jcb('JCB', [16, 17, 18, 19], 3),
  unionPay('UnionPay', [16, 17, 18, 19], 3),
  maestro('Maestro', [12, 13, 14, 15, 16, 17, 18, 19], 3);

  const CardType(this.displayName, this.validLengths, this.cvvLength);

  final String displayName;
  final List<int> validLengths;
  final int cvvLength;

  // e.g. "13, 16 or 19"
  String get validLengthsLabel {
    if (validLengths.length == 1) return '${validLengths.single}';
    final isRange =
        validLengths.last - validLengths.first == validLengths.length - 1;
    if (isRange && validLengths.length > 2) {
      return '${validLengths.first} to ${validLengths.last}';
    }
    final head = validLengths.sublist(0, validLengths.length - 1).join(', ');
    return '$head or ${validLengths.last}';
  }
}
