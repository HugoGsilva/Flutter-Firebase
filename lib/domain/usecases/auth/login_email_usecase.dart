import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/preference_repository.dart';
import 'cadastrar_usuario_usecase.dart';

class LoginEmailUseCase {
  const LoginEmailUseCase(this._repository, this._preferences);

  final AuthRepository _repository;
  final PreferenceRepository _preferences;

  Future<Result<UsuarioModel>> call({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();

    if (!emailValido(emailLimpo)) {
      return const Failure(FormatException('Informe um e-mail válido.'));
    }
    if (senha.isEmpty) {
      return const Failure(FormatException('Informe a senha.'));
    }

    try {
      final usuario = await _repository.loginComEmail(
        email: emailLimpo,
        senha: senha,
      );
      await _preferences.salvarUsuarioEmCache(usuario);
      return Success(usuario);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
