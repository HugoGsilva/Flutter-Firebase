import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../repositories/auth_repository.dart';

class AlterarSenhaUseCase {
  const AlterarSenhaUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({
    required String senhaAtual,
    required String novaSenha,
    required String confirmacaoSenha,
  }) async {
    final atual = _repository.usuarioAtual;
    if (atual == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }
    if (!atual.podeAlterarSenha) {
      return const Failure(
        AppException(
          'Contas conectadas com o Google gerenciam a senha pela Conta Google.',
        ),
      );
    }
    if (senhaAtual.isEmpty) {
      return const Failure(FormatException('Informe a senha atual.'));
    }
    if (novaSenha.length < 6) {
      return const Failure(
        FormatException('A nova senha deve ter no mínimo 6 caracteres.'),
      );
    }
    if (novaSenha != confirmacaoSenha) {
      return const Failure(
        FormatException('A confirmação da nova senha não confere.'),
      );
    }
    if (novaSenha == senhaAtual) {
      return const Failure(
        FormatException('A nova senha deve ser diferente da senha atual.'),
      );
    }

    try {
      await _repository.alterarSenha(
        senhaAtual: senhaAtual,
        novaSenha: novaSenha,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
