import '../../../core/result/result.dart';
import '../../repositories/pessoa_repository.dart';

class RemoverPessoaUseCase {
  const RemoverPessoaUseCase(this._repository);

  final PessoaRepository _repository;

  Future<Result<void>> call(String id, {required bool confirmado}) async {
    if (!confirmado) {
      return Failure(
        Exception('A exclusão deve ser confirmada pelo usuário.'),
      );
    }

    if (id.trim().isEmpty) {
      return const Failure(FormatException('ID da pessoa não pode ser vazio.'));
    }

    try {
      await _repository.removerPessoa(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
