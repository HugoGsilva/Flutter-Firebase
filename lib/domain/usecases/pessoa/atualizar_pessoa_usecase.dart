import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/pessoa_model.dart';
import '../../repositories/pessoa_repository.dart';

class AtualizarPessoaUseCase {
  const AtualizarPessoaUseCase(this._repository);

  final PessoaRepository _repository;

  Future<Result<PessoaModel>> call(PessoaModel pessoa) async {
    if (pessoa.id.trim().isEmpty) {
      return const Failure(FormatException('Pessoa sem identificador.'));
    }

    final erro = pessoa.validar();
    if (erro != null) return Failure(FormatException(erro));

    try {
      final atual = await _repository.buscarPorId(pessoa.id);
      if (atual == null) {
        return const Failure(AppException('Pessoa não encontrada.'));
      }

      final atualizada = pessoa.normalizada().copyWith(
        criadoPor: atual.criadoPor,
      );
      await _repository.atualizarPessoa(atualizada);
      return Success(atualizada);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
