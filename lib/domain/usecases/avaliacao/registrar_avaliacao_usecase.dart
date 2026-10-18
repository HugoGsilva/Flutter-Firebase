import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../repositories/avaliacao_repository.dart';
import 'validar_avaliacao_usecase.dart';

class RegistrarAvaliacaoUseCase {
  const RegistrarAvaliacaoUseCase(this._repository, this._validar);

  final AvaliacaoRepository _repository;
  final ValidarAvaliacaoUseCase _validar;

  Future<Result<AvaliacaoModel>> call({
    required String pessoaId,
    required Map<String, int> notas,
  }) async {
    final validacao = await _validar(pessoaId: pessoaId, notas: notas);
    if (validacao case Failure(error: final erro)) return Failure(erro);
    final avaliacao = validacao.dataOrNull!;

    try {
      final existente = await _repository.buscarAvaliacao(
        avaliacao.avaliadorUid,
        pessoaId,
      );
      if (existente != null) {
        return const Failure(
          AppException(
            'Você já avaliou esta pessoa. Altere a avaliação existente.',
          ),
        );
      }

      await _repository.salvarAvaliacao(avaliacao);
      return Success(avaliacao);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
