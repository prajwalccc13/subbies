import 'package:intl/intl.dart';

final _currency = NumberFormat.simpleCurrency(locale: 'en_AU');

String get currencySymbol => _currency.currencySymbol;

String formatCents(num cents) => _currency.format(cents / 100);

int? parseCents(String text) {
  final value = double.tryParse(text.trim());
  if (value == null) return null;

  return (value * 100).round();
}