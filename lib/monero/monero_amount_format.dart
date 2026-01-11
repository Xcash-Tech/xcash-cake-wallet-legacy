import 'package:intl/intl.dart';
import 'package:cake_wallet/entities/crypto_amount_format.dart';

// X-CASH: display amounts with 2 decimals.
const moneroAmountLength = 2;
const moneroAmountDivider = 1000000;
final moneroAmountFormat = NumberFormat()
  ..maximumFractionDigits = moneroAmountLength
  ..minimumFractionDigits = moneroAmountLength;

String moneroAmountToString({int amount}) => moneroAmountFormat
    .format(cryptoAmountToDouble(amount: amount, divider: moneroAmountDivider));

double moneroAmountToDouble({int amount}) =>
    cryptoAmountToDouble(amount: amount, divider: moneroAmountDivider);

int moneroParseAmount({String amount}) =>
    (double.parse(amount) * moneroAmountDivider).toInt();
