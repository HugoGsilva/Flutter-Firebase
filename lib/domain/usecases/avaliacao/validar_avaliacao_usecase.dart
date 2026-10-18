import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../models/criterios_avaliacao.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/pessoa_repository.dart';
import 'verificar_autoavaliacao_usecase.dart';

/// Regras comuns ao registrar e ao alterar uma avaliação. Devolve a
/// avaliação pronta para ser persistida, com a pontuação total calculada.
class ValidarAvaliacaoUseCase {
  const ValidarAvaliacaoUseCase(
    this._authRepository,
    this._pessoaRepository,
    this._verificarAutoavaliacao,
  );

  final AuthRepository _authRepository;
  final PessoaRepository _pessoaRepository;
  final VerificarAutoavaliacaoUseCase _verificarAutoavaliacao;

  Future<Result<AvaliacaoModel>> call({
    required String pessoaId,
    required Map<String, int> notas,
  }) async {
    final avaliador = _authRepository.usuarioAtual;
    if (avaliador == null) {
      return const Failure(
        AppException('Você precisa estar autenticado para avaliar.'),
      );
    }

    if (pessoaId.trim().isEmpty) {
      return const Failure(
        FormatException('Identificador da pessoa avaliada não pode ser vazio.'),
      );
    }

    if (!CriterioAvaliacao.validarNotas(notas)) {
      return const Failure(
        FormatException(
          'Todos os 15 critérios devem receber uma nota entre 1 e 5.',
        ),
      );
    }

    try {
      final pessoa = await _pessoaRepository.buscarPorId(pessoaId);
      if (pessoa == null) {
        return const Failure(AppException('Pessoa avaliada não encontrada.'));
      }

      final auto = await _verificarAutoavaliacao(pessoaId);
      if (auto case Failure(error: final erro)) return Failure(erro);
      if (auto.dataOrNull == true) {
        return const Failure(
          AppException('Não é permitido avaliar a si próprio.'),
        );
      }

      return Success(
        AvaliacaoModel(
          id: AvaliacaoModel.gerarIdCanonico(avaliador.uid, pessoaId),
          avaliadorUid: avaliador.uid,
          pessoaId: pessoaId,
          notas: Map.unmodifiable(notas),
          pontuacaoTotal: CriterioAvaliacao.calcularPontuacaoTotal(notas),
          dataAvaliacao: DateTime.now(),
        ),
      );
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
