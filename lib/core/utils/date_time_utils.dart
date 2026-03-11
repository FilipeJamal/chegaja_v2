import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  // Construtor privado para evitar instanciacao
  DateTimeUtils._();

  /// Formata data/hora completa (ex: 12 Jan 2024 14:30)
  /// Converte para local time automaticamente.
  static String formatDateTime(dynamic date, {String? locale}) {
    final dt = _toDateTime(date);
    if (dt == null) return '-';
    // DateFormat.yMMMd().add_hm() -> "Jan 12, 2024 2:30 PM" (depende do locale)
    return DateFormat.yMMMd(locale).add_jm().format(dt.toLocal());
  }

  /// Formata apenas data (ex: 12 Jan 2024)
  static String formatDate(dynamic date, {String? locale}) {
    final dt = _toDateTime(date);
    if (dt == null) return '-';
    return DateFormat.yMMMd(locale).format(dt.toLocal());
  }

  /// Formata apenas hora (ex: 14:30)
  static String formatTime(dynamic date, {String? locale}) {
    final dt = _toDateTime(date);
    if (dt == null) return '-';
    return DateFormat.jm(locale).format(dt.toLocal());
  }

  /// Helper seguro para converter Timestamp ou String para DateTime
  static DateTime? _toDateTime(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }
}
