import '../../../core/result/result.dart';
import '../../models/usuario_model.dart';
import '../../repositories/auth_repository.dart';

class CadastrarUsuarioUseCase {
  const CadastrarUsuarioUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UsuarioModel>> call({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim();

    if (nomeLimpo.isEmpty) {
      return const Failure(FormatException('O nome não pode ser vazio.'));
    }
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return const Failure(FormatException('Informe um e-mail válido.'));
    }
    if (senha.length < 6) {
      return const Failure(
        FormatException('A senha deve ter no mínimo 6 caracteres.'),
      );
    }

    try {
      final usuario = await _repository.cadastrarComEmail(
        nome: nomeLimpo,
        email: emailLimpo,
        senha: senha,
      );
      return Success(usuario);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
