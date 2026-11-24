import '../../../core/result/result.dart';
import '../../repositories/auth_repository.dart';
import 'cadastrar_usuario_usecase.dart';

class RecuperarSenhaUseCase {
  const RecuperarSenhaUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) async {
    final emailLimpo = email.trim();
    if (!emailValido(emailLimpo)) {
      return const Failure(FormatException('Informe um e-mail válido.'));
    }

    try {
      await _repository.enviarRecuperacaoSenha(email: emailLimpo);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
