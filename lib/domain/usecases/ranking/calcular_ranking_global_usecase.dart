import '../../../core/result/result.dart';
import '../../models/avaliacao_model.dart';
import '../../models/ranking_item_model.dart';
import '../../repositories/avaliacao_repository.dart';
import '../../repositories/pessoa_repository.dart';
import 'calcular_ranking_pessoal_usecase.dart';

/// Ranking produzido a partir das avaliações de todos os usuários. A
/// pontuação de cada pessoa é a média das avaliações que ela recebeu.
class CalcularRankingGlobalUseCase {
  const CalcularRankingGlobalUseCase(
    this._pessoaRepository,
    this._avaliacaoRepository,
  );

  final PessoaRepository _pessoaRepository;
  final AvaliacaoRepository _avaliacaoRepository;

  Future<Result<List<RankingItemModel>>> call() async {
    try {
      final pessoas = await _pessoaRepository.listarTodas();
      final avaliacoes = await _avaliacaoRepository.listarTodas();

      final porPessoa = <String, List<AvaliacaoModel>>{};
      for (final avaliacao in avaliacoes) {
        porPessoa.putIfAbsent(avaliacao.pessoaId, () => []).add(avaliacao);
      }

      final itens = <RankingItemModel>[];
      for (final pessoa in pessoas) {
        final recebidas = porPessoa[pessoa.id];
        if (recebidas == null || recebidas.isEmpty) continue;

        final soma = recebidas.fold<int>(0, (t, a) => t + a.pontuacaoTotal);
        final media = soma / recebidas.length;

        itens.add(
          RankingItemModel(
            pessoa: pessoa,
            pontuacao: media.round(),
            mediaPontuacao: media,
            totalAvaliacoes: recebidas.length,
            posicao: 0,
          ),
        );
      }

      itens.sort((a, b) {
        final porMedia = b.mediaPontuacao.compareTo(a.mediaPontuacao);
        if (porMedia != 0) return porMedia;
        final porQuantidade = b.totalAvaliacoes.compareTo(a.totalAvaliacoes);
        if (porQuantidade != 0) return porQuantidade;
        return a.pessoa.nome.compareTo(b.pessoa.nome);
      });

      return Success(numerarPosicoes(itens));
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
