import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/domain/models/criterios_avaliacao.dart';
import 'package:piramid_game/presentation/viewmodels/auth_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/avaliacao_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/pessoa_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/theme_viewmodel.dart';

import '../../integration_test/support/fakes.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    setupDependencies(
      authRepository: backend.auth,
      pessoaRepository: backend.pessoas,
      avaliacaoRepository: backend.avaliacoes,
      preferenceRepository: backend.preferencias,
    );
  });

  group('AuthViewModel', () {
    test('cadastro autentica e notifica o router', () async {
      final vm = sl<AuthViewModel>();
      var notificacoes = 0;
      vm.isAuthenticated.addListener(() => notificacoes++);

      await vm.cadastroCommand('Ana', 'ana@ifpr.edu.br', '123456');

      expect(vm.isAuthenticated.value, isTrue);
      expect(vm.currentUser.value?.nome, 'Ana');
      expect(notificacoes, 1);
      expect(vm.cadastroCommand.running, isFalse);
    });

    test('falha de login preenche errorMessage', () async {
      final vm = sl<AuthViewModel>();
      final r = await vm.loginCommand('x@y.com', '123456');
      expect(r.isFailure, isTrue);
      expect(vm.errorMessage.value, 'E-mail ou senha incorretos.');
      expect(vm.isAuthenticated.value, isFalse);
    });

    test('verificarSessao restaura usuário e logout limpa', () async {
      backend.auth.entrarComo(usuarioAna);
      backend.preferencias.cache = usuarioAna;
      final vm = sl<AuthViewModel>();

      await vm.carregarCache();
      expect(vm.nomeEmCache.value, 'Ana Clara');

      await vm.verificarSessaoCommand();
      expect(vm.currentUser.value?.uid, usuarioAna.uid);

      await vm.logoutCommand();
      expect(vm.isAuthenticated.value, isFalse);
      expect(backend.preferencias.cache, isNull);
    });
  });

  group('PessoaViewModel', () {
    setUp(() => backend.auth.entrarComo(usuarioAna));

    test(
      'cadastrar, filtrar, alterar e remover atualizam os signals',
      () async {
        final vm = sl<PessoaViewModel>();
        await vm.cadastrarPessoaCommand(
          novaPessoa(nome: 'Bruno', curso: 'MEC'),
        );
        await vm.cadastrarPessoaCommand(
          novaPessoa(nome: 'Ana', apelido: 'Aninha'),
        );
        expect(vm.pessoas.value.map((p) => p.nome), ['Ana', 'Bruno']);

        vm.setFiltroCurso('MEC');
        expect(vm.pessoasFiltradas.value.single.nome, 'Bruno');
        vm.setFiltroCurso(null);
        vm.setBuscaTexto('aninha');
        expect(vm.pessoasFiltradas.value.single.nome, 'Ana');
        vm.limparFiltros();
        expect(vm.pessoasFiltradas.value, hasLength(2));

        final ana = vm.pessoas.value.first;
        await vm.alterarPessoaCommand(ana.copyWith(nome: 'Ana Clara'));
        expect(vm.pessoaPorId(ana.id)?.nome, 'Ana Clara');

        await vm.removerPessoaCommand(ana.id, true);
        expect(vm.pessoaPorId(ana.id), isNull);
      },
    );

    test('buscarPessoaCommand traz pessoa que não estava carregada', () async {
      final salva = await backend.pessoas.cadastrarPessoa(novaPessoa());
      final vm = sl<PessoaViewModel>();
      expect(vm.pessoaPorId(salva.id), isNull);
      await vm.buscarPessoaCommand(salva.id);
      expect(vm.pessoaPorId(salva.id)?.nome, salva.nome);
    });

    test('erro de validação é exposto em errorMessage', () async {
      final vm = sl<PessoaViewModel>();
      await vm.cadastrarPessoaCommand(novaPessoa(apelido: ''));
      expect(vm.errorMessage.value, contains('apelido'));
      vm.limparErro();
      expect(vm.errorMessage.value, isNull);
    });
  });

  group('AvaliacaoViewModel', () {
    late String pessoaId;

    setUp(() async {
      backend.auth.entrarComo(usuarioAna);
      pessoaId = (await backend.pessoas.cadastrarPessoa(novaPessoa())).id;
    });

    test('começa com 15 critérios e pontuação reativa', () {
      final vm = sl<AvaliacaoViewModel>();
      expect(vm.notas.value, hasLength(15));
      expect(vm.pontuacaoTotal.value, 45);

      vm.definirNota(CriterioAvaliacao.aura, 5);
      expect(vm.pontuacaoTotal.value, 47);

      vm.definirNota(CriterioAvaliacao.aura, 9);
      expect(vm.notas.value['aura'], 5, reason: 'nota inválida é ignorada');
    });

    test('avaliar registra e a segunda vez altera a mesma avaliação', () async {
      final vm = sl<AvaliacaoViewModel>();
      await vm.carregarAvaliacaoCommand(pessoaId);
      expect(vm.avaliacaoExistente.value, isNull);

      await vm.avaliarPessoaCommand(pessoaId);
      expect(vm.avaliacaoExistente.value?.pontuacaoTotal, 45);
      expect(vm.minhasAvaliacoes.value[pessoaId]?.pontuacaoTotal, 45);

      await vm.carregarAvaliacaoCommand(pessoaId);
      for (final c in CriterioAvaliacao.values) {
        vm.definirNota(c, 5);
      }
      final r = await vm.avaliarPessoaCommand(pessoaId);
      expect(r.isSuccess, isTrue);
      expect(backend.avaliacoes.dados.values.single.pontuacaoTotal, 75);
    });

    test('carregar avaliação detecta autoavaliação', () async {
      await backend.auth.vincularPessoa(usuarioAna.uid, pessoaId);
      final vm = sl<AvaliacaoViewModel>();
      await vm.carregarAvaliacaoCommand(pessoaId);
      expect(vm.isAutoavaliacao.value, isTrue);

      final r = await vm.avaliarPessoaCommand(pessoaId);
      expect(r.isFailure, isTrue);
      expect(vm.errorMessage.value, contains('si próprio'));
    });
  });

  group('RankingViewModel', () {
    test('carrega rankings pessoal e global', () async {
      backend.auth.entrarComo(usuarioAna);
      final p = await backend.pessoas.cadastrarPessoa(novaPessoa());
      final avaliacaoVm = sl<AvaliacaoViewModel>();
      for (final c in CriterioAvaliacao.values) {
        avaliacaoVm.definirNota(c, 4);
      }
      await avaliacaoVm.avaliarPessoaCommand(p.id);

      final vm = sl<RankingViewModel>();
      await vm.carregarRankingPessoalCommand();
      await vm.carregarRankingGlobalCommand();

      expect(vm.rankingPessoal.value.single.pontuacao, 60);
      expect(vm.rankingGlobal.value.single.totalAvaliacoes, 1);
      expect(vm.posicaoGlobalDe(p.id)?.posicao, 1);

      vm.limpar();
      expect(vm.rankingGlobal.value, isEmpty);
    });
  });

  group('ThemeViewModel', () {
    test('carrega o tema salvo e alterna persistindo', () async {
      backend.preferencias.temaEscuro = true;
      final vm = sl<ThemeViewModel>();
      await vm.carregarTemaCommand();
      expect(vm.isDarkMode.value, isTrue);

      await vm.alternarTemaCommand();
      expect(vm.isDarkMode.value, isFalse);
      expect(backend.preferencias.temaEscuro, isFalse);
    });
  });
}
