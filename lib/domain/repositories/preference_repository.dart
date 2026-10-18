import '../models/usuario_model.dart';

abstract interface class PreferenceRepository {
  Future<void> salvarTemaEscuro(bool isDark);
  Future<bool?> obterTemaEscuro();

  /// Cache simples do usuário autenticado (nunca inclui a senha).
  Future<void> salvarUsuarioEmCache(UsuarioModel usuario);
  Future<UsuarioModel?> obterUsuarioEmCache();
  Future<void> limparSessao();
}
