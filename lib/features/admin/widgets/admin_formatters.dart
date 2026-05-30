int adminAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

int? adminMaybeInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double adminAsDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0;
}

double? adminMaybeDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

String adminMoneyCents(Object? value) {
  final cents = adminAsInt(value);
  final euros = cents / 100.0;
  return 'EUR ${euros.toStringAsFixed(2)}';
}

String adminMoneyCentsOrDash(Object? value) {
  final cents = adminMaybeInt(value);
  if (cents == null) return '-';
  final euros = cents / 100.0;
  return 'EUR ${euros.toStringAsFixed(2)}';
}

String adminPercentRatio(Object? value) {
  final ratio = adminMaybeDouble(value);
  if (ratio == null) return '-';
  final percent = ratio * 100;
  if (percent == percent.roundToDouble()) return '${percent.round()}%';
  return '${percent.toStringAsFixed(1)}%';
}

String adminPercentFromParts({
  required int numerator,
  required int denominator,
}) {
  if (denominator <= 0) return '-';
  final percent = (numerator / denominator) * 100;
  if (percent == percent.roundToDouble()) return '${percent.round()}%';
  return '${percent.toStringAsFixed(1)}%';
}

String adminFormatMs(Object? value) {
  final ms = adminAsInt(value);
  if (ms <= 0) return '-';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
