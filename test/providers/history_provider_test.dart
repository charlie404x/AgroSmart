import 'package:agrosmart_peru/providers/history_provider.dart';
import 'package:agrosmart_peru/services/agro_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeHttpAdapter http;
  late HistoryProvider history;

  setUp(() {
    http = FakeHttpAdapter()
      ..on('GET', '/history/', (_) => FakeResponse(200, fixture('history_response.json')));
    history = HistoryProvider(AgroService(fakeApi(http)));
  });

  test('carga el historial y calcula indicadores', () async {
    await history.loadIfNeeded();
    expect(history.loadedOnce, isTrue);
    expect(history.items, isNotEmpty);
    expect(history.total, history.items.length);
    expect(history.latest!.id, history.items.first.id);
    expect(history.mostFrequentCrop, isNotNull);
    expect(history.hasMore, isFalse);
  });

  test('eliminar es optimista y se revierte si falla', () async {
    await history.loadIfNeeded();
    final id = history.items.first.id;
    http.on(
      'DELETE',
      '/history/$id',
      (_) => const FakeResponse(404, {'detail': 'No encontramos esa consulta en tu historial.'}),
    );
    final error = await history.delete(id);
    expect(error, contains('No encontramos'));
    expect(history.items.any((e) => e.id == id), isTrue);
  });

  test('eliminar con éxito quita el elemento', () async {
    await history.loadIfNeeded();
    final id = history.items.first.id;
    final before = history.total;
    http.on('DELETE', '/history/$id', (_) => const FakeResponse(204, null));
    expect(await history.delete(id), isNull);
    expect(history.items.any((e) => e.id == id), isFalse);
    expect(history.total, before - 1);
  });

  test('error de red se informa en español', () async {
    http.on('GET', '/history/', (_) => const FakeResponse(500, {'detail': 'boom'}));
    await history.refresh();
    expect(history.errorMessage, 'El servidor tuvo un problema. Inténtalo más tarde.');
  });

  test('reset al cerrar sesión limpia todo', () async {
    await history.loadIfNeeded();
    history.reset();
    expect(history.items, isEmpty);
    expect(history.loadedOnce, isFalse);
  });
}
