import '../../domain/models/usuario_model.dart';
import '../../domain/repositories/preference_repository.dart';
import '../services/local_storage_service.dart';

class PreferenceRepositoryImpl implements PreferenceRepository {
  PreferenceRepositoryImpl(this._localStorageService);

  final LocalStorageService _localStorageService;

  @override
  Future<void> salvarTemaEscuro(bool isDark) {
    return _localStorageService.salvarTemaEscuro(isDark);
  }

  @override
  Future<bool?> obterTemaEscuro() {
    return _localStorageService.obterTemaEscuro();
  }

  @override
  Future<void> salvarUsuarioEmCache(UsuarioModel usuario) {
    return _localStorageService.salvarUsuarioCache({
      'uid': usuario.uid,
      ...usuario.toMap(),
    });
  }

  @override
  Future<UsuarioModel?> obterUsuarioEmCache() async {
    final dados = await _localStorageService.obterUsuarioCache();
    return dados != null ? UsuarioModel.fromMap(dados) : null;
  }

  @override
  Future<void> limparSessao() {
    return _localStorageService.limparCacheSessao();
  }
}
