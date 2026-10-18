import '../../../core/result/app_exception.dart';
import '../../../core/result/result.dart';
import '../../models/ranking_item_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/avaliacao_repository.dart';
import '../../repositories/pessoa_repository.dart';

/// Ranking produzido exclusivamente a partir das avaliações feitas pelo
/// usuário autenticado.
class CalcularRankingPessoalUseCase {
  const CalcularRankingPessoalUseCase(
    this._pessoaRepository,
    this._avaliacaoRepository,
    this._authRepository,
  );

  final PessoaRepository _pessoaRepository;
  final AvaliacaoRepository _avaliacaoRepository;
  final AuthRepository _authRepository;

  Future<Result<List<RankingItemModel>>> call() async {
    final usuario = _authRepository.usuarioAtual;
    if (usuario == null) {
      return const Failure(AppException('Você precisa estar autenticado.'));
    }

    try {
      final pessoas = await _pessoaRepository.listarTodas();
      final avaliacoes = await _avaliacaoRepository.listarPorAvaliador(
        usuario.uid,
      );
      final pessoasPorId = {for (final p in pessoas) p.id: p};

      final itens = <RankingItemModel>[
        for (final avaliacao in avaliacoes)
          if (pessoasPorId[avaliacao.pessoaId] case final pessoa?)
            RankingItemModel(
              pessoa: pessoa,
              pontuacao: avaliacao.pontuacaoTotal,
              mediaPontuacao: avaliacao.pontuacaoTotal.toDouble(),
              totalAvaliacoes: 1,
              posicao: 0,
            ),
      ];

      itens.sort((a, b) {
        final porPontuacao = b.pontuacao.compareTo(a.pontuacao);
        if (porPontuacao != 0) return porPontuacao;
        return a.pessoa.nome.compareTo(b.pessoa.nome);
      });

      return Success(numerarPosicoes(itens));
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}

List<RankingItemModel> numerarPosicoes(List<RankingItemModel> ordenados) {
  return [
    for (var i = 0; i < ordenados.length; i++)
      ordenados[i].copyWith(posicao: i + 1),
  ];
}
