import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../models/criterios_avaliacao.dart';
import '../../repositories/avaliacao_repository.dart';

class SalvarAvaliacaoUseCase {
  const SalvarAvaliacaoUseCase(this._repository);

  final AvaliacaoRepository _repository;

  Future<Result<void>> call(
    AvaliacaoModel avaliacao, {
    String? pessoaCriadorUid,
  }) async {
    if (avaliacao.avaliadorUid.trim().isEmpty) {
      return const Failure(
        FormatException('Identificador do avaliador não pode ser vazio.'),
      );
    }

    if (avaliacao.pessoaId.trim().isEmpty) {
      return const Failure(
        FormatException('Identificador da pessoa avaliada não pode ser vazio.'),
      );
    }

    // Bloqueio de autoavaliação
    if (pessoaCriadorUid != null &&
        avaliacao.avaliadorUid == pessoaCriadorUid) {
      return Failure(
        Exception('Não é permitido avaliar a si mesmo.'),
      );
    }

    // Validação dos 15 critérios com notas de 1 a 5
    if (!CriterioAvaliacao.validarNotas(avaliacao.notas)) {
      return const Failure(
        FormatException(
          'Todas as 15 notas devem ser fornecidas e ter valor entre 1 e 5.',
        ),
      );
    }

    final pontuacaoCalculada =
        CriterioAvaliacao.calcularPontuacaoTotal(avaliacao.notas);

    if (pontuacaoCalculada < CriterioAvaliacao.pontuacaoMinima ||
        pontuacaoCalculada > CriterioAvaliacao.pontuacaoMaxima) {
      return const Failure(
        FormatException('A pontuação total deve estar entre 15 e 75 pontos.'),
      );
    }

    try {
      final avaliacaoCorrigida = avaliacao.copyWith(
        id: AvaliacaoModel.gerarIdCanonico(
          avaliacao.avaliadorUid,
          avaliacao.pessoaId,
        ),
        pontuacaoTotal: pontuacaoCalculada,
      );
      await _repository.salvarAvaliacao(avaliacaoCorrigida);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
