import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/history_entry.dart';
import '../models/recommendation_result.dart';
import '../services/agro_service.dart';

/// Historial de consultas del usuario autenticado, con paginación.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._service);

  final AgroService _service;
  final Map<int, RecommendationResult> _detailCache = {};

  List<HistoryEntry> _items = const [];
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loadedOnce = false;
  String? _errorMessage;

  List<HistoryEntry> get items => _items;
  int get total => _total;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get loadedOnce => _loadedOnce;
  bool get hasMore => _items.length < _total;
  String? get errorMessage => _errorMessage;
  HistoryEntry? get latest => _items.isEmpty ? null : _items.first;

  /// Cultivo que más veces aparece entre los 3 primeros de las consultas cargadas.
  String? get mostFrequentCrop {
    final counts = <String, int>{};
    for (final entry in _items) {
      for (final crop in entry.topCrops) {
        counts[crop] = (counts[crop] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  Future<void> loadIfNeeded() async {
    if (!_loadedOnce && !_isLoading) await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _service.history();
      _items = page.items;
      _total = page.total;
      _loadedOnce = true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.history(offset: _items.length);
      final known = _items.map((e) => e.id).toSet();
      _items = [..._items, ...page.items.where((e) => !known.contains(e.id))];
      _total = page.total;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Detalle completo de una consulta (con caché en memoria).
  Future<RecommendationResult> detail(int id) async {
    final cached = _detailCache[id];
    if (cached != null) return cached;
    final result = await _service.historyDetail(id);
    _detailCache[id] = result;
    return result;
  }

  /// Elimina una consulta. Devuelve un mensaje de error o null si tuvo éxito.
  Future<String?> delete(int id) async {
    final previous = _items;
    final previousTotal = _total;
    _items = _items.where((e) => e.id != id).toList();
    _total = (_total - 1).clamp(0, 1 << 30);
    notifyListeners();
    try {
      await _service.deleteHistory(id);
      _detailCache.remove(id);
      return null;
    } on ApiException catch (e) {
      _items = previous;
      _total = previousTotal;
      notifyListeners();
      return e.message;
    }
  }

  void reset() {
    _items = const [];
    _total = 0;
    _loadedOnce = false;
    _errorMessage = null;
    _detailCache.clear();
    notifyListeners();
  }
}
