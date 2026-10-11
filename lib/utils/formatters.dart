import 'package:intl/intl.dart';

/// Shared money / date formatting so the app, the PDF and the bill list agree.
class Fmt {
  Fmt._();

  static final NumberFormat _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateTime = DateFormat('dd MMM, hh:mm a');

  /// `1234.5` -> `₹1,234.50`
  static String money(double value) => _money.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  /// Compact form for list rows, e.g. `11 Oct, 04:20 PM`.
  static String shortDateTime(DateTime value) => _shortDateTime.format(value);

  /// Drops a trailing `.0` so `10.0` shows as `10` and `7.5` stays `7.5`.
  static String percent(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
