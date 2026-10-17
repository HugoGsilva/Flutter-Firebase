import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/domain/models/criterios_avaliacao.dart';

void main() {
  group('CriterioAvaliacao e Nível Lenda', () {
    test('deve conter exatamente os 15 critérios especificados', () {
      expect(CriterioAvaliacao.values.length, 15);
      final nomes = CriterioAvaliacao.values.map((c) => c.nome).toList();
      expect(
        nomes,
        containsAll([
          'Resenha',
          'Presença VIP',
          'Aura',
          'Modo Parceiro',
          'Carisma Natural',
          'Humor de Milhões',
          'Energia de Grupo',
          'Criatividade Caótica',
          'Modo Atleta',
          'Talento de Palco',
          'Drip Escolar',
          'Coração de Dorama',
          'Queridinho dos Professores',
          'Cérebro Turbo',
          'Caos Controlado',
        ]),
      );
    });

    test('deve validar notas individuais apenas entre 1 e 5', () {
      expect(CriterioAvaliacao.isNotaValida(0), isFalse);
      expect(CriterioAvaliacao.isNotaValida(1), isTrue);
      expect(CriterioAvaliacao.isNotaValida(3), isTrue);
      expect(CriterioAvaliacao.isNotaValida(5), isTrue);
      expect(CriterioAvaliacao.isNotaValida(6), isFalse);
      expect(CriterioAvaliacao.isNotaValida(-1), isFalse);
    });

    test('deve calcular corretamente a pontuação mínima (15) e máxima (75)', () {
      final notasMinimas = {
        for (final c in CriterioAvaliacao.values) c.id: 1,
      };
      final notasMaximas = {
        for (final c in CriterioAvaliacao.values) c.id: 5,
      };

      expect(CriterioAvaliacao.validarNotas(notasMinimas), isTrue);
      expect(CriterioAvaliacao.validarNotas(notasMaximas), isTrue);

      expect(
        CriterioAvaliacao.calcularPontuacaoTotal(notasMinimas),
        equals(15),
      );
      expect(
        CriterioAvaliacao.calcularPontuacaoTotal(notasMaximas),
        equals(75),
      );
    });

    test('deve invalidar mapa de notas com critério faltando ou nota fora da faixa', () {
      final notasIncompletas = {
        'resenha': 5,
        'aura': 4,
      };
      expect(CriterioAvaliacao.validarNotas(notasIncompletas), isFalse);

      final notasComInvalida = {
        for (final c in CriterioAvaliacao.values) c.id: 3,
      };
      notasComInvalida['resenha'] = 6;
      expect(CriterioAvaliacao.validarNotas(notasComInvalida), isFalse);
    });
  });
}
