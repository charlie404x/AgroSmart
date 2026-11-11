import 'package:agrosmart_peru/models/user.dart';
import 'package:agrosmart_peru/utils/jwt_utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';

void main() {
  test('lee el vencimiento de un JWT', () {
    final exp = jwtExpiry(fakeJwt())!;
    expect(exp.difference(DateTime.now()).inMinutes, inInclusiveRange(29, 30));
  });

  test('token inválido devuelve null', () {
    expect(jwtExpiry('no-es-un-jwt'), isNull);
    expect(jwtExpiry('a.%%%.c'), isNull);
  });

  test('AuthSession.isExpired', () {
    const user = User(email: 'a@b.pe', fullName: 'Ana');
    final past = AuthSession(
      token: 't',
      user: user,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    final future = AuthSession(
      token: 't',
      user: user,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    expect(past.isExpired(), isTrue);
    expect(future.isExpired(), isFalse);
  });

  test('AuthSession se serializa y restaura', () {
    final s = AuthSession(
      token: 'abc',
      user: const User(email: 'ana@example.com', fullName: 'Ana Quispe'),
      expiresAt: DateTime.utc(2030),
    );
    final restored = AuthSession.fromJson(s.toJson());
    expect(restored.token, 'abc');
    expect(restored.user.fullName, 'Ana Quispe');
    expect(restored.expiresAt!.toUtc(), DateTime.utc(2030));
  });

  test('User.initials y firstName', () {
    const u = User(email: 'ana@example.com', fullName: 'Ana  Quispe Mamani');
    expect(u.initials, 'AM');
    expect(u.firstName, 'Ana');
    expect(const User(email: 'luis@x.pe', fullName: '').initials, 'L');
  });
}
