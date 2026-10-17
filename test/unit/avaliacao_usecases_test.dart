import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/domain/models/avaliacao_model.dart';
import 'package:piramid_game/domain/models/criterios_avaliacao.dart';
import 'package:piramid_game/domain/repositories/avaliacao_repository.dart';
import 'package:piramid_game/domain/usecases/avaliacao/salvar_avaliacao_usecase.dart';
import 'package:piramid_game/domain/usecases/avaliacao/verificar_autoavaliacao_usecase.dart';

class MockAvaliacaoRepository implements AvaliacaoRepository {
  AvaliacaoModel? ultimaSalva;

  @override
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {
    ultimaSalva = avaliacao;
  }

  @override
  Future<AvaliacaoModel?> buscarAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async =>
      ultimaSalva;

  @override
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId) async => [];

  @override
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid) async =>
      [];

  @override
  Future<List<AvaliacaoModel>> listarTodas() async => [];
}

void main() {
  group('UseCases de Avaliação e Regras de Negócio', () {
    late MockAvaliacaoRepository mockRepo;
    late SalvarAvaliacaoUseCase salvarUseCase;
    late VerificarAutoavaliacaoUseCase autoavaliacaoUseCase;

    setUp(() {
      mockRepo = MockAvaliacaoRepository();
      salvarUseCase = SalvarAvaliacaoUseCase(mockRepo);
      autoavaliacaoUseCase = const VerificarAutoavaliacaoUseCase();
    });

    final notasValidas = {
      for (final c in CriterioAvaliacao.values) c.id: 4,
    };

    test('deve bloquear autoavaliação quando avaliadorUid é o mesmo do criador', () async {
      final avaliacao = AvaliacaoModel(
        id: '',
        avaliadorUid: 'usuario_123',
        pessoaId: 'pessoa_999',
        notas: notasValidas,
        pontuacaoTotal: 60,
        dataAvaliacao: DateTime.now(),
      );

      final resultado = await salvarUseCase(
        avaliacao,
        pessoaCriadorUid: 'usuario_123',
      );

      expect(resultado.isFailure, isTrue);
      expect(
        resultado.errorOrNull.toString(),
        contains('Não é permitido avaliar a si mesmo'),
      );
      expect(mockRepo.ultimaSalva, isNull);
    });

    test('deve detectar autoavaliação pelo VerificarAutoavaliacaoUseCase', () {
      final resMesmoUid = autoavaliacaoUseCase(
        avaliadorUid: 'uid_a',
        pessoaCriadorUid: 'uid_a',
      );
      expect(resMesmoUid.isSuccess, isTrue);
      expect(resMesmoUid.dataOrNull, isTrue);

      final resMesmoId = autoavaliacaoUseCase(
        avaliadorUid: 'id_123',
        pessoaCriadorUid: 'outro_uid',
        pessoaId: 'id_123',
      );
      expect(resMesmoId.isSuccess, isTrue);
      expect(resMesmoId.dataOrNull, isTrue);

      final resOutro = autoavaliacaoUseCase(
        avaliadorUid: 'uid_a',
        pessoaCriadorUid: 'uid_b',
        pessoaId: 'pessoa_c',
      );
      expect(resOutro.isSuccess, isTrue);
      expect(resOutro.dataOrNull, isFalse);
    });

    test('deve falhar ao salvar se notas contiverem valor fora da faixa de 1 a 5', () async {
      final notasInvalidas = Map<String, int>.from(notasValidas);
      notasInvalidas['resenha'] = 6;

      final avaliacao = AvaliacaoModel(
        id: '',
        avaliadorUid: 'avaliador_1',
        pessoaId: 'pessoa_2',
        notas: notasInvalidas,
        pontuacaoTotal: 60,
        dataAvaliacao: DateTime.now(),
      );

      final resultado = await salvarUseCase(
        avaliacao,
        pessoaCriadorUid: 'outro_usuario',
      );

      expect(resultado.isFailure, isTrue);
      expect(
        resultado.errorOrNull.toString(),
        contains('Todas as 15 notas devem ser fornecidas e ter valor entre 1 e 5'),
      );
    });

    test('deve salvar com sucesso quando notas e usuários são válidos', () async {
      final avaliacao = AvaliacaoModel(
        id: '',
        avaliadorUid: 'avaliador_1',
        pessoaId: 'pessoa_2',
        notas: notasValidas,
        pontuacaoTotal: 60,
        dataAvaliacao: DateTime.now(),
      );

      final resultado = await salvarUseCase(
        avaliacao,
        pessoaCriadorUid: 'outro_usuario',
      );

      expect(resultado.isSuccess, isTrue);
      expect(mockRepo.ultimaSalva, isNotNull);
      expect(mockRepo.ultimaSalva!.id, 'avaliador_1_pessoa_2');
      expect(mockRepo.ultimaSalva!.pontuacaoTotal, 60);
    });
  });
}
