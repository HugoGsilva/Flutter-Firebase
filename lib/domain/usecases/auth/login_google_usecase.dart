import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';

class LoginGoogleUseCase {
  const LoginGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UsuarioModel>> call() async {
    try {
      final usuario = await _repository.loginComGoogle();
      return Success(usuario);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
