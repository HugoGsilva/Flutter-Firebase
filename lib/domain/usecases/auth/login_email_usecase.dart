import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';

class LoginEmailUseCase {
  const LoginEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UsuarioModel>> call({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();

    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
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
      return Success(usuario);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
