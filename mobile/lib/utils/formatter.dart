import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  if (amount == null) return 'Rp 0';
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return formatter.format(amount);
}

String formatPercent(double percent) {
  return '${percent.toStringAsFixed(1)}%';
}