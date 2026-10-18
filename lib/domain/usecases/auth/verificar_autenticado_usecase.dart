import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';

/// A sessão válida é sempre decidida pelo Firebase Authentication; o cache
/// local apenas é atualizado ou descartado conforme o resultado.
class VerificarAutenticadoUseCase {
  const VerificarAutenticadoUseCase(this._repository, this._preferences);

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel?>> call() async {
    try {
      final usuario = await _repository.restaurarSessao();
      if (usuario == null) {
        await _preferences.limparSessao();
      } else {
        await _preferences.salvarUsuarioEmCache(usuario);
      }
      return Success(usuario);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  Future<UsuarioModel?> usuarioEmCache() => _preferences.obterUsuarioEmCache();
}
