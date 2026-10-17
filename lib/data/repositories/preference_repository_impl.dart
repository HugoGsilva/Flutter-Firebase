import '../../domain/repositories/preference_repository.dart';
import '../services/local_storage_service.dart';

class PreferenceRepositoryImpl implements PreferenceRepository {
  PreferenceRepositoryImpl(this._localStorageService);

  final LocalStorageService _localStorageService;

  @override
  Future<void> salvarTemaEscuro(bool isDark) async {
    await _localStorageService.salvarTemaEscuro(isDark);
  }

  @override
  Future<bool?> obterTemaEscuro() async {
    return _localStorageService.obterTemaEscuro();
  }

  @override
  Future<void> salvarUltimoUid(String uid) async {
    await _localStorageService.salvarUltimoUid(uid);
  }

  @override
  Future<String?> obterUltimoUid() async {
    return _localStorageService.obterUltimoUid();
  }

  @override
  Future<void> limparSessao() async {
    await _localStorageService.limparCacheSessao();
  }
}
