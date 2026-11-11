import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/climate_info.dart';
import '../services/agro_service.dart';

/// Clima referencial por departamento, con caché por sesión.
class ClimateProvider extends ChangeNotifier {
  ClimateProvider(this._service);

  final AgroService _service;
  final Map<String, ClimateInfo> _cache = {};
  final Map<String, String> _errors = {};
  final Set<String> _loading = {};

  ClimateInfo? climateFor(String department) => _cache[department];
  String? errorFor(String department) => _errors[department];
  bool isLoading(String department) => _loading.contains(department);

  Future<void> load(String department, {bool force = false}) async {
    if (_loading.contains(department)) return;
    if (!force && _cache.containsKey(department)) return;
    _loading.add(department);
    _errors.remove(department);
    notifyListeners();
    try {
      _cache[department] = await _service.climate(department);
    } on ApiException catch (e) {
      _errors[department] = e.message;
    } finally {
      _loading.remove(department);
      notifyListeners();
    }
  }

  void reset() {
    _cache.clear();
    _errors.clear();
    notifyListeners();
  }
}
