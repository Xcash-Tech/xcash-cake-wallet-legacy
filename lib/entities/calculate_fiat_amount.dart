String calculateFiatAmount({double price, String cryptoAmount}) {
  if (price == null || cryptoAmount == null) {
    return '0.00';
  }

  // Remove commas from formatted numbers before parsing
  final cleanAmount = cryptoAmount.replaceAll(',', '');
  final _amount = double.tryParse(cleanAmount) ?? 0.0;
  final _result = price * _amount;
  final result = _result < 0 ? _result * -1 : _result;

  if (result == 0.0) {
    return '0.00';
  }

  return result > 0.01 ? result.toStringAsFixed(2) : '< 0.01';
}
