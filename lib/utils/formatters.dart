/// Formateo de números, montos y fechas en español (Perú) sin dependencias externas.
class Formatters {
  Formatters._();

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  /// Agrupa miles con espacio fino: 10000 -> "10 000".
  static String groupThousands(num value, {int decimals = 0}) {
    final fixed = value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u202F');
      buffer.write(digits[i]);
    }
    final sign = value < 0 ? '-' : '';
    final dec = parts.length > 1 ? '.${parts[1]}' : '';
    return '$sign$buffer$dec';
  }

  /// Monto en soles: 10000 -> "S/ 10 000"; 0.8 -> "S/ 0.80".
  static String soles(num value, {int? decimals}) {
    final d = decimals ?? (value.abs() < 100 ? 2 : 0);
    return 'S/ ${groupThousands(value, decimals: d)}';
  }

  static String altitude(num meters) => '${groupThousands(meters.round())} m';

  static String tonnesPerHa(num value) => '${value.toStringAsFixed(1)} t/ha';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String time(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

  /// "11 nov 2026"
  static String shortDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// "miércoles, 11 de noviembre"
  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} de ${_monthsLong[date.month - 1]}';

  /// "Hoy, 14:05" · "Ayer, 09:30" · "8 nov 2026, 18:10"
  static String relativeDateTime(DateTime date, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy, ${time(date)}';
    if (diff == 1) return 'Ayer, ${time(date)}';
    return '${shortDate(date)}, ${time(date)}';
  }

  /// Saludo según la hora del día.
  static String greeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
