abstract interface class PreferenceRepository {
  Future<void> salvarTemaEscuro(bool isDark);
  Future<bool?> obterTemaEscuro();
  Future<void> salvarUltimoUid(String uid);
  Future<String?> obterUltimoUid();
  Future<void> limparSessao();
}
