import '../../domain/models/avaliacao_model.dart';
import '../../domain/models/ranking_item_model.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../../domain/repositories/pessoa_repository.dart';
import '../../domain/repositories/ranking_repository.dart';

class RankingRepositoryImpl implements RankingRepository {
  RankingRepositoryImpl(this._pessoaRepository, this._avaliacaoRepository);

  final PessoaRepository _pessoaRepository;
  final AvaliacaoRepository _avaliacaoRepository;

  @override
  Future<List<RankingItemModel>> obterRankingPessoal(String avaliadorUid) async {
    final pessoas = await _pessoaRepository.listarTodas();
    final avaliacoes =
        await _avaliacaoRepository.listarPorAvaliador(avaliadorUid);

    final pessoasMap = {for (final p in pessoas) p.id: p};
    final itens = <RankingItemModel>[];

    for (final avaliacao in avaliacoes) {
      final pessoa = pessoasMap[avaliacao.pessoaId];
      if (pessoa != null) {
        itens.add(
          RankingItemModel(
            pessoa: pessoa,
            pontuacao: avaliacao.pontuacaoTotal,
            mediaPontuacao: avaliacao.pontuacaoTotal.toDouble(),
            totalAvaliacoes: 1,
            posicao: 0,
          ),
        );
      }
    }

    // Ordenação decrescente pela pontuação
    itens.sort((a, b) => b.pontuacao.compareTo(a.pontuacao));

    return [
      for (int i = 0; i < itens.length; i++)
        itens[i].copyWith(posicao: i + 1),
    ];
  }

  @override
  Future<List<RankingItemModel>> obterRankingGlobal() async {
    final pessoas = await _pessoaRepository.listarTodas();
    final avaliacoes = await _avaliacaoRepository.listarTodas();

    final avaliacoesPorPessoa = <String, List<AvaliacaoModel>>{};
    for (final avaliacao in avaliacoes) {
      avaliacoesPorPessoa
          .putIfAbsent(avaliacao.pessoaId, () => [])
          .add(avaliacao);
    }

    final itens = <RankingItemModel>[];

    for (final pessoa in pessoas) {
      final lista = avaliacoesPorPessoa[pessoa.id] ?? const [];
      final total = lista.length;
      final double media;
      final int pontuacaoFinal;

      if (total > 0) {
        final soma = lista.fold<int>(
          0,
          (acumulado, av) => acumulado + av.pontuacaoTotal,
        );
        media = soma / total;
        pontuacaoFinal = media.round();
      } else {
        media = 0.0;
        pontuacaoFinal = 0;
      }

      itens.add(
        RankingItemModel(
          pessoa: pessoa,
          pontuacao: pontuacaoFinal,
          mediaPontuacao: media,
          totalAvaliacoes: total,
          posicao: 0,
        ),
      );
    }

    // Ordena por média decrescente, total de avaliações e nome
    itens.sort((a, b) {
      final compMedia = b.mediaPontuacao.compareTo(a.mediaPontuacao);
      if (compMedia != 0) return compMedia;
      final compTotal = b.totalAvaliacoes.compareTo(a.totalAvaliacoes);
      if (compTotal != 0) return compTotal;
      return a.pessoa.nome.compareTo(b.pessoa.nome);
    });

    return [
      for (int i = 0; i < itens.length; i++)
        itens[i].copyWith(posicao: i + 1),
    ];
  }
}
