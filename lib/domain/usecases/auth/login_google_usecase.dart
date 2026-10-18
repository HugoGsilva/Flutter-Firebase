import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';

class LoginGoogleUseCase {
  const LoginGoogleUseCase(this._repository, this._preferences);

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel>> call() async {
    try {
      final usuario = await _repository.loginComGoogle();
      await _preferences.salvarUsuarioEmCache(usuario);
      return Success(usuario);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
