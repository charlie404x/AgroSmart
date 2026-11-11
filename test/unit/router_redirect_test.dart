import 'package:agrosmart_peru/providers/auth_provider.dart';
import 'package:agrosmart_peru/routes/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('estado desconocido siempre va al splash', () {
    expect(AppRouter.redirect(AuthStatus.unknown, '/home'), '/splash');
    expect(AppRouter.redirect(AuthStatus.unknown, '/splash'), isNull);
  });

  test('sin sesión sólo permite login y registro', () {
    expect(AppRouter.redirect(AuthStatus.unauthenticated, '/home'), '/login');
    expect(AppRouter.redirect(AuthStatus.unauthenticated, '/history/3'), '/login');
    expect(AppRouter.redirect(AuthStatus.unauthenticated, '/splash'), '/login');
    expect(AppRouter.redirect(AuthStatus.unauthenticated, '/register'), isNull);
  });

  test('con sesión no vuelve a pantallas de acceso', () {
    expect(AppRouter.redirect(AuthStatus.authenticated, '/login'), '/home');
    expect(AppRouter.redirect(AuthStatus.authenticated, '/splash'), '/home');
    expect(AppRouter.redirect(AuthStatus.authenticated, '/results'), isNull);
  });
}
