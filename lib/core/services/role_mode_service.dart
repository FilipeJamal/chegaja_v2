import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleModeService extends ChangeNotifier {
  RoleModeService._();

  RoleModeService.forTesting();

  static final RoleModeService instance = RoleModeService._();

  static const String storageKey = 'app_role_mode';

  bool _isLoaded = false;
  String? _currentRole;

  bool get isLoaded => _isLoaded;

  String? get currentRole => _currentRole;

  Future<void> load({
    String? urlRole,
    String? defaultRole,
    bool force = false,
  }) async {
    if (_isLoaded && !force) return;

    final prefs = await SharedPreferences.getInstance();
    final persistedRole = prefs.getString(storageKey);
    _currentRole = normalizeInitialRole(urlRole) ??
        normalizeRole(persistedRole) ??
        normalizeInitialRole(defaultRole);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setMode(String role) async {
    final normalized = normalizeRole(role);
    if (normalized == null) return;

    final changed = _currentRole != normalized || !_isLoaded;
    _currentRole = normalized;
    _isLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, normalized);

    if (changed) notifyListeners();
  }

  Future<void> clearMode() async {
    final changed = _currentRole != null || !_isLoaded;
    _currentRole = null;
    _isLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);

    if (changed) notifyListeners();
  }

  static String? normalizeRole(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'cliente' || normalized == 'prestador') {
      return normalized;
    }
    return null;
  }

  static String? normalizeInitialRole(String? value) {
    final normalized = normalizeRole(value);
    if (normalized != null) return normalized;

    final raw = value?.trim().toLowerCase();
    if (raw == 'admin') return raw;
    return null;
  }
}
