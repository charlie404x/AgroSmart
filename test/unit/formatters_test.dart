import 'package:agrosmart_peru/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agrupa miles con espacio fino', () {
    expect(Formatters.groupThousands(10000), '10\u202F000');
    expect(Formatters.groupThousands(999), '999');
    expect(Formatters.groupThousands(1234567), '1\u202F234\u202F567');
  });

  test('soles usa 2 decimales para montos pequeños', () {
    expect(Formatters.soles(0.8), 'S/ 0.80');
    expect(Formatters.soles(10000), 'S/ 10\u202F000');
  });

  test('fechas en español', () {
    final d = DateTime(2026, 11, 11, 9, 5);
    expect(Formatters.shortDate(d), '11 nov 2026');
    expect(Formatters.longDate(d), 'miércoles, 11 de noviembre');
    expect(Formatters.relativeDateTime(d, now: DateTime(2026, 11, 11, 20)), 'Hoy, 09:05');
    expect(Formatters.relativeDateTime(d, now: DateTime(2026, 11, 12, 8)), 'Ayer, 09:05');
    expect(Formatters.relativeDateTime(d, now: DateTime(2026, 11, 20)), '11 nov 2026, 09:05');
  });

  test('saludo según la hora', () {
    expect(Formatters.greeting(now: DateTime(2026, 1, 1, 8)), 'Buenos días');
    expect(Formatters.greeting(now: DateTime(2026, 1, 1, 15)), 'Buenas tardes');
    expect(Formatters.greeting(now: DateTime(2026, 1, 1, 21)), 'Buenas noches');
  });
}
