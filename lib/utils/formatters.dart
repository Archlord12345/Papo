import 'package:intl/intl.dart';

String formatAmount(double amount, String asset) {
  if (asset == 'BTC') {
    return '${amount.toStringAsFixed(6)} BTC';
  }
  final formatter = NumberFormat('#,##0', 'fr_FR');
  final sign = amount >= 0 ? '+' : '';
  return '$sign${formatter.format(amount)} $asset';
}

String formatAmountAbs(double amount, String asset) {
  if (asset == 'BTC') {
    return '${amount.abs().toStringAsFixed(6)} BTC';
  }
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return '${formatter.format(amount.abs())} $asset';
}

String formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dt);
  } catch (_) {
    return isoDate;
  }
}

String formatDateShort(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd MMM', 'fr_FR').format(dt);
  } catch (_) {
    return isoDate;
  }
}

String timeAgo(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  } catch (_) {
    return '';
  }
}
