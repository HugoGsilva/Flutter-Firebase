import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/domain/models/avaliacao_model.dart';
import 'package:piramid_game/domain/models/criterios_avaliacao.dart';
import 'package:piramid_game/domain/models/pessoa_model.dart';
import 'package:piramid_game/domain/models/usuario_model.dart';

import '../../integration_test/support/fakes.dart';

void main() {
  group('CriterioAvaliacao', () {
    test('possui os 15 critérios com os nomes de campo do Firestore', () {
      expect(CriterioAvaliacao.values.map((c) => c.id), [
        'resenha',
        'presencaVip',
        'aura',
        'modoParceiro',
        'carismaNatural',
        'humorDeMilhoes',
        'energiaDeGrupo',
        'criatividadeCaotica',
        'modoAtleta',
        'talentoDePalco',
        'dripEscolar',
        'coracaoDeDorama',
        'queridinhoProfessores',
        'cerebroTurbo',
        'caosControlado',
      ]);
    });

    test('pontuação mínima 15 e máxima 75', () {
      expect(CriterioAvaliacao.calcularPontuacaoTotal(notasIguais(1)), 15);
      expect(CriterioAvaliacao.calcularPontuacaoTotal(notasIguais(5)), 75);
    });

    test('exemplo do João Pedro soma 58 pontos', () {
      expect(CriterioAvaliacao.calcularPontuacaoTotal(notasExemploJoao), 58);
    });

    test('rejeita notas fora de 1..5 ou critérios faltando', () {
      expect(CriterioAvaliacao.validarNotas(notasIguais(3)), isTrue);
      expect(
        CriterioAvaliacao.validarNotas({...notasIguais(3), 'aura': 0}),
        isFalse,
      );
      expect(
        CriterioAvaliacao.validarNotas({...notasIguais(3), 'aura': 6}),
        isFalse,
      );
      expect(
        CriterioAvaliacao.validarNotas(Map.of(notasIguais(3))..remove('aura')),
        isFalse,
      );
    });
  });

  group('AvaliacaoModel', () {
    test('serializa cada critério como campo próprio e volta igual', () {
      final avaliacao = AvaliacaoModel(
        id: 'uid_ana_pes_1',
        avaliadorUid: 'uid_ana',
        pessoaId: 'pes_1',
        notas: notasExemploJoao,
        pontuacaoTotal: 58,
        dataAvaliacao: DateTime(2026, 10, 1, 10, 30),
      );

      final mapa = avaliacao.toMap();
      expect(mapa['avaliadorUid'], 'uid_ana');
      expect(mapa['pessoaId'], 'pes_1');
      expect(mapa['aura'], 5);
      expect(mapa['talentoDePalco'], 2);
      expect(mapa['pontuacaoTotal'], 58);
      expect(mapa.containsKey('notas'), isFalse);

      final lida = AvaliacaoModel.fromMap(mapa, id: 'uid_ana_pes_1');
      expect(lida.notas, notasExemploJoao);
      expect(lida.pontuacaoTotal, 58);
      expect(lida.dataAvaliacao, DateTime(2026, 10, 1, 10, 30));
    });

    test('id canônico une avaliador e pessoa', () {
      expect(AvaliacaoModel.gerarIdCanonico('u1', 'p1'), 'u1_p1');
    });
  });

  group('PessoaModel', () {
    test('valida curso, turma, nome, apelido e nascimento', () {
      expect(novaPessoa().validar(), isNull);
      expect(novaPessoa(curso: 'MEDICINA').validar(), contains('Curso'));
      expect(novaPessoa(turma: 1997).validar(), contains('1998'));
      expect(novaPessoa(turma: 2027).validar(), contains('2026'));
      expect(novaPessoa(nome: ' ').validar(), contains('nome'));
      expect(novaPessoa(apelido: '').validar(), contains('apelido'));
      expect(
        novaPessoa()
            .copyWith(
              dataNascimento: DateTime.now().add(const Duration(days: 2)),
            )
            .validar(),
        contains('futuro'),
      );
    });

    test('aceita todos os cursos da especificação', () {
      for (final curso in ['INFO', 'MEC', 'MAMB', 'PROD', 'TADS', 'TGA']) {
        expect(novaPessoa(curso: curso).validar(), isNull, reason: curso);
      }
    });

    test('toMap/fromMap preservam os dados e o id vem do documento', () {
      final pessoa = novaPessoa(id: 'pes_9');
      final mapa = pessoa.toMap();
      expect(mapa.containsKey('id'), isFalse);
      final lida = PessoaModel.fromMap(mapa, id: 'pes_9');
      expect(lida.nome, pessoa.nome);
      expect(lida.turma, 2024);
      expect(lida.dataNascimento, DateTime(2007, 5, 12));
      expect(lida.criadoPor, 'uid_ana');
      expect(lida.id, 'pes_9');
    });
  });

  group('UsuarioModel', () {
    test('mantém o vínculo com a pessoa e nunca guarda senha', () {
      final usuario = usuarioAna.comPessoaVinculada('pes_1');
      final mapa = usuario.toMap();
      expect(mapa['pessoaId'], 'pes_1');
      expect(mapa.keys, isNot(contains('senha')));
      expect(UsuarioModel.fromMap(mapa, uid: 'uid_ana').pessoaId, 'pes_1');
      expect(usuario.comPessoaVinculada(null).pessoaId, isNull);
    });
  });
}
