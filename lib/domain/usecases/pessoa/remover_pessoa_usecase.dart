import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/pessoa_repository.dart';

/// Regra do sistema: somente quem cadastrou a pessoa pode removê-la, e a
/// remoção precisa ter sido confirmada pelo usuário.
class RemoverPessoaUseCase {
  const RemoverPessoaUseCase(this._repository, this._authRepository);

  final PessoaRepository _repository;
  final AuthRepository _authRepository;

  Future<Result<void>> call(String id, {required bool confirmado}) async {
    if (!confirmado) {
      return const Failure(
        AppException('A exclusão deve ser confirmada pelo usuário.'),
      );
    }

    if (id.trim().isEmpty) {
      return const Failure(FormatException('ID da pessoa não pode ser vazio.'));
    }

    final usuario = _authRepository.usuarioAtual;
    if (usuario == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }

    try {
      final pessoa = await _repository.buscarPorId(id);
      if (pessoa == null) {
        return const Failure(AppException('Pessoa não encontrada.'));
      }
      if (pessoa.criadoPor != usuario.uid) {
        return const Failure(
          AppException('Somente quem cadastrou a pessoa pode removê-la.'),
        );
      }

      await _repository.removerPessoa(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
