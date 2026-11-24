import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';

class RemoverFotoPerfilUseCase {
  const RemoverFotoPerfilUseCase(this._repository, this._preferences);

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel>> call() async {
    if (_repository.usuarioAtual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }

    try {
      final atualizado = await _repository.removerFotoPerfil();
      await _preferences.salvarUsuarioEmCache(atualizado);
      return Success(atualizado);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
