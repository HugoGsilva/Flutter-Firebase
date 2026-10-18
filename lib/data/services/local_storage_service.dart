import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService({SharedPreferences? preferences}) {
    _preferences = preferences;
  }

  SharedPreferences? _preferences;

  static const String _temaEscuroKey = 'app_tema_escuro';
  static const String _usuarioCacheKey = 'app_usuario_cache';

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

  Future<void> salvarUsuarioCache(Map<String, dynamic> dados) async {
    final prefs = await _getPrefs();
    await prefs.setString(_usuarioCacheKey, jsonEncode(dados));
  }

  Future<Map<String, dynamic>?> obterUsuarioCache() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_usuarioCacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      await prefs.remove(_usuarioCacheKey);
      return null;
    }
  }

  Future<void> limparCacheSessao() async {
    final prefs = await _getPrefs();
    await prefs.remove(_usuarioCacheKey);
  }
}
