import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias no sensibles del usuario (por ejemplo, el último departamento consultado).
class AppPreferences extends ChangeNotifier {
  AppPreferences(this._prefs) : _lastDepartment = _prefs.getString(_lastDepartmentKey);

  static const _lastDepartmentKey = 'last_department';
  final SharedPreferences _prefs;
  String? _lastDepartment;

  String? get lastDepartment => _lastDepartment;

  Future<void> setLastDepartment(String department) async {
    if (_lastDepartment == department) return;
    _lastDepartment = department;
    notifyListeners();
    await _prefs.setString(_lastDepartmentKey, department);
  }

  Future<void> clear() async {
    _lastDepartment = null;
    notifyListeners();
    await _prefs.remove(_lastDepartmentKey);
  }
}
