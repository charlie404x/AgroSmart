import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/recommendation_result.dart';
import '../services/agro_service.dart';

/// Envía el formulario del terreno y conserva el último resultado.
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider(this._service);

  final AgroService _service;
  RecommendationResult? _current;
  bool _isLoading = false;
  String? _errorMessage;

  RecommendationResult? get current => _current;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<RecommendationResult?> submit(FarmInput input) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _current = await _service.recommend(input);
      return _current;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _current = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
