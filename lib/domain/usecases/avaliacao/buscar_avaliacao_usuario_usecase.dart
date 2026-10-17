import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../repositories/avaliacao_repository.dart';

class BuscarAvaliacaoUsuarioUseCase {
  const BuscarAvaliacaoUsuarioUseCase(this._repository);

  final AvaliacaoRepository _repository;

  Future<Result<AvaliacaoModel?>> call({
    required String avaliadorUid,
    required String pessoaId,
  }) async {
    if (avaliadorUid.trim().isEmpty || pessoaId.trim().isEmpty) {
      return const Failure(
        FormatException(
          'Identificadores do avaliador e da pessoa são obrigatórios.',
        ),
      );
    }

    try {
      final avaliacao = await _repository.buscarAvaliacao(
        avaliadorUid,
        pessoaId,
      );
      return Success(avaliacao);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
