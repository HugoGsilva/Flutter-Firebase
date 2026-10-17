import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/data/repositories/ranking_repository_impl.dart';
import 'package:piramid_game/domain/models/avaliacao_model.dart';
import 'package:piramid_game/domain/models/pessoa_model.dart';
import 'package:piramid_game/domain/repositories/avaliacao_repository.dart';
import 'package:piramid_game/domain/repositories/pessoa_repository.dart';

class FakePessoaRepository implements PessoaRepository {
  FakePessoaRepository(this.pessoas);

  final List<PessoaModel> pessoas;

  @override
  Future<void> cadastrarPessoa(PessoaModel pessoa) async {}

  @override
  Future<void> atualizarPessoa(PessoaModel pessoa) async {}

  @override
  Future<void> removerPessoa(String id) async {}

  @override
  Future<PessoaModel?> buscarPorId(String id) async {
    return pessoas.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<List<PessoaModel>> listarTodas() async => pessoas;
}

class FakeAvaliacaoRepository implements AvaliacaoRepository {
  FakeAvaliacaoRepository(this.avaliacoes);

  final List<AvaliacaoModel> avaliacoes;

  @override
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {}

  @override
  Future<AvaliacaoModel?> buscarAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async {
    return avaliacoes
        .where((a) => a.avaliadorUid == avaliadorUid && a.pessoaId == pessoaId)
        .firstOrNull;
  }

  @override
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId) async {
    return avaliacoes.where((a) => a.pessoaId == pessoaId).toList();
  }

  @override
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid) async {
    return avaliacoes.where((a) => a.avaliadorUid == avaliadorUid).toList();
  }

  @override
  Future<List<AvaliacaoModel>> listarTodas() async => avaliacoes;
}

void main() {
  group('RankingRepositoryImpl', () {
    final pessoaAna = PessoaModel(
      id: 'p1',
      nome: 'Ana Clara',
      apelido: 'Ana',
      curso: 'INFO',
      turma: 2024,
      dataNascimento: DateTime(2006, 5, 10),
      criadoPor: 'user_x',
    );

    final pessoaJoao = PessoaModel(
      id: 'p2',
      nome: 'João Pedro',
      apelido: 'JP',
      curso: 'MEC',
      turma: 2023,
      dataNascimento: DateTime(2005, 8, 20),
      criadoPor: 'user_y',
    );

    final pessoaMaria = PessoaModel(
      id: 'p3',
      nome: 'Maria Eduarda',
      apelido: 'Duda',
      curso: 'MAMB',
      turma: 2025,
      dataNascimento: DateTime(2007, 2, 15),
      criadoPor: 'user_z',
    );

    test(
      'deve calcular corretamente a média e posições do ranking global',
      () async {
        final avaliacoes = [
          // Ana: 60 + 70 -> média 65.0 (2 avaliações)
          AvaliacaoModel(
            id: 'u1_p1',
            avaliadorUid: 'u1',
            pessoaId: 'p1',
            notas: const {},
            pontuacaoTotal: 60,
            dataAvaliacao: DateTime.now(),
          ),
          AvaliacaoModel(
            id: 'u2_p1',
            avaliadorUid: 'u2',
            pessoaId: 'p1',
            notas: const {},
            pontuacaoTotal: 70,
            dataAvaliacao: DateTime.now(),
          ),
          // João: 58 (1 avaliação) -> média 58.0
          AvaliacaoModel(
            id: 'u1_p2',
            avaliadorUid: 'u1',
            pessoaId: 'p2',
            notas: const {},
            pontuacaoTotal: 58,
            dataAvaliacao: DateTime.now(),
          ),
          // Maria: 54 (1 avaliação) -> média 54.0
          AvaliacaoModel(
            id: 'u1_p3',
            avaliadorUid: 'u1',
            pessoaId: 'p3',
            notas: const {},
            pontuacaoTotal: 54,
            dataAvaliacao: DateTime.now(),
          ),
        ];

        final rankingRepo = RankingRepositoryImpl(
          FakePessoaRepository([pessoaAna, pessoaJoao, pessoaMaria]),
          FakeAvaliacaoRepository(avaliacoes),
        );

        final ranking = await rankingRepo.obterRankingGlobal();

        expect(ranking.length, 3);

        expect(ranking[0].pessoa.nome, 'Ana Clara');
        expect(ranking[0].posicao, 1);
        expect(ranking[0].mediaPontuacao, 65.0);
        expect(ranking[0].totalAvaliacoes, 2);
        expect(ranking[0].pontuacao, 65);

        expect(ranking[1].pessoa.nome, 'João Pedro');
        expect(ranking[1].posicao, 2);
        expect(ranking[1].mediaPontuacao, 58.0);
        expect(ranking[1].totalAvaliacoes, 1);
        expect(ranking[1].pontuacao, 58);

        expect(ranking[2].pessoa.nome, 'Maria Eduarda');
        expect(ranking[2].posicao, 3);
        expect(ranking[2].mediaPontuacao, 54.0);
        expect(ranking[2].totalAvaliacoes, 1);
        expect(ranking[2].pontuacao, 54);
      },
    );

    test(
      'deve ordenar ranking pessoal pelas notas atribuídas pelo avaliador',
      () async {
        final avaliacoes = [
          AvaliacaoModel(
            id: 'u1_p1',
            avaliadorUid: 'u1',
            pessoaId: 'p1',
            notas: const {},
            pontuacaoTotal: 68,
            dataAvaliacao: DateTime.now(),
          ),
          AvaliacaoModel(
            id: 'u1_p2',
            avaliadorUid: 'u1',
            pessoaId: 'p2',
            notas: const {},
            pontuacaoTotal: 58,
            dataAvaliacao: DateTime.now(),
          ),
        ];

        final rankingRepo = RankingRepositoryImpl(
          FakePessoaRepository([pessoaAna, pessoaJoao, pessoaMaria]),
          FakeAvaliacaoRepository(avaliacoes),
        );

        final rankingPessoal = await rankingRepo.obterRankingPessoal('u1');

        expect(rankingPessoal.length, 2);
        expect(rankingPessoal[0].pessoa.nome, 'Ana Clara');
        expect(rankingPessoal[0].posicao, 1);
        expect(rankingPessoal[0].pontuacao, 68);

        expect(rankingPessoal[1].pessoa.nome, 'João Pedro');
        expect(rankingPessoal[1].posicao, 2);
        expect(rankingPessoal[1].pontuacao, 58);
      },
    );
  });
}
