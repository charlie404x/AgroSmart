import 'package:agrosmart_peru/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('acepta correos válidos', () {
      expect(Validators.email('ana@example.com'), isNull);
      expect(Validators.email('  ana.q+agro@correo.pe '), isNull);
    });
    test('rechaza vacío o mal formado con mensaje en español', () {
      expect(Validators.email(''), 'Ingresa tu correo electrónico');
      expect(Validators.email('ana@'), contains('correo válido'));
      expect(Validators.email('ana.example.com'), isNotNull);
    });
  });

  group('Validators.newPassword (misma política que el backend)', () {
    test('exige 8 caracteres, letras y números', () {
      expect(Validators.newPassword('Cultivo2026'), isNull);
      expect(Validators.newPassword('abc1'), contains('al menos 8 caracteres'));
      expect(Validators.newPassword('soloLetras'), contains('números'));
      expect(Validators.newPassword('12345678'), contains('letras'));
    });
    test('passwordIssues vacío cuando cumple todo', () {
      expect(Validators.passwordIssues('Papa2026x'), isEmpty);
    });
  });

  test('confirmPassword', () {
    expect(Validators.confirmPassword('a', 'b'), 'Las contraseñas no coinciden');
    expect(Validators.confirmPassword('abc', 'abc'), isNull);
  });

  group('Validators.altitude', () {
    test('acepta formatos comunes', () {
      expect(Validators.parseAltitude('3200'), 3200);
      expect(Validators.parseAltitude('3 200'), 3200);
      expect(Validators.parseAltitude('3200,5'), 3200.5);
      expect(Validators.altitude('0'), isNull);
      expect(Validators.altitude('5000'), isNull);
    });
    test('rechaza fuera de rango, negativos y texto', () {
      expect(Validators.altitude('-1'), contains('entre 0 y 5000'));
      expect(Validators.altitude('5001'), contains('entre 0 y 5000'));
      expect(Validators.altitude('alto'), contains('números'));
      expect(Validators.altitude(''), isNotNull);
    });
  });
}
