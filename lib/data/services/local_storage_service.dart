import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService({SharedPreferences? preferences}) {
    if (preferences != null) {
      _preferences = preferences;
    }
  }

  SharedPreferences? _preferences;

  static const String _temaEscuroKey = 'app_tema_escuro';
  static const String _ultimoUidKey = 'app_ultimo_uid';

  Future<SharedPreferences> _getPrefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> salvarTemaEscuro(bool isDark) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_temaEscuroKey, isDark);
  }

  Future<bool?> obterTemaEscuro() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_temaEscuroKey);
  }

  Future<void> salvarUltimoUid(String uid) async {
    final prefs = await _getPrefs();
    await prefs.setString(_ultimoUidKey, uid);
  }

  Future<String?> obterUltimoUid() async {
    final prefs = await _getPrefs();
    return prefs.getString(_ultimoUidKey);
  }

  Future<void> limparCacheSessao() async {
    final prefs = await _getPrefs();
    await prefs.remove(_ultimoUidKey);
  }
}
