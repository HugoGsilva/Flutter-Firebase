import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/core/result/app_exception.dart';
import 'package:piramid_game/core/result/result.dart';
import 'package:piramid_game/domain/facades/auth_facade.dart';
import 'package:piramid_game/domain/facades/avaliacao_facade.dart';
import 'package:piramid_game/domain/facades/pessoa_facade.dart';
import 'package:piramid_game/domain/facades/ranking_facade.dart';
import 'package:piramid_game/domain/facades/tema_facade.dart';
import 'package:piramid_game/domain/models/pessoa_model.dart';

import '../../integration_test/support/fakes.dart';

String erroDe(Result<Object?> r) => mensagemDoErro(r.errorOrNull!);

void main() {
  late FakeBackend backend;
  late AuthFacade auth;
  late PessoaFacade pessoas;
  late AvaliacaoFacade avaliacoes;
  late RankingFacade ranking;

  setUp(() {
    backend = FakeBackend();
    setupDependencies(
      authRepository: backend.auth,
      pessoaRepository: backend.pessoas,
      avaliacaoRepository: backend.avaliacoes,
      preferenceRepository: backend.preferencias,
    );
    auth = sl<AuthFacade>();
    pessoas = sl<PessoaFacade>();
    avaliacoes = sl<AvaliacaoFacade>();
    ranking = sl<RankingFacade>();
  });

  Future<PessoaModel> cadastrar(
    String nome, {
    String apelido = 'Apelido',
  }) async {
    final r = await pessoas.cadastrar(novaPessoa(nome: nome, apelido: apelido));
    return r.dataOrNull!;
  }

  group('Autenticação', () {
    test(
      'cria conta, faz cache da sessão (sem senha) e permite login',
      () async {
        final r = await auth.criarConta(
          nome: ' Ana Clara ',
          email: 'ana@ifpr.edu.br',
          senha: '123456',
        );
        expect(r.isSuccess, isTrue);
        expect(r.dataOrNull!.nome, 'Ana Clara');
        expect(backend.preferencias.cache?.email, 'ana@ifpr.edu.br');

        await auth.logout();
        expect(backend.preferencias.cache, isNull);

        final login = await auth.login(
          email: 'ana@ifpr.edu.br',
          senha: '123456',
        );
        expect(login.isSuccess, isTrue);
      },
    );

    test('valida dados antes de chamar o Firebase', () async {
      expect(
        erroDe(
          await auth.criarConta(nome: '', email: 'a@b.com', senha: '123456'),
        ),
        contains('nome'),
      );
      expect(
        erroDe(
          await auth.criarConta(nome: 'Ana', email: 'ana', senha: '123456'),
        ),
        contains('e-mail'),
      );
      expect(
        erroDe(
          await auth.criarConta(nome: 'Ana', email: 'a@b.com', senha: '123'),
        ),
        contains('6 caracteres'),
      );
      expect(
        erroDe(await auth.login(email: 'a@b.com', senha: '')),
        contains('senha'),
      );
    });

    test('credenciais erradas viram Failure com mensagem amigável', () async {
      final r = await auth.login(email: 'nao@existe.com', senha: '123456');
      expect(erroDe(r), 'E-mail ou senha incorretos.');
    });

    test('login com Google', () async {
      backend.auth.contaGoogle = usuarioJoao.copyWith(provider: 'google.com');
      final r = await auth.loginComGoogle();
      expect(r.dataOrNull?.provider, 'google.com');
      expect(backend.preferencias.cache?.uid, usuarioJoao.uid);
    });

    test('verificar autenticação: sem sessão limpa o cache', () async {
      backend.preferencias.cache = usuarioAna;
      final r = await auth.verificarAutenticacao();
      expect(r.isSuccess, isTrue);
      expect(r.dataOrNull, isNull);
      expect(backend.preferencias.cache, isNull);
    });

    test(
      'verificar autenticação: sessão válida devolve perfil completo',
      () async {
        backend.auth.entrarComo(usuarioAna.comPessoaVinculada('pes_x'));
        final r = await auth.verificarAutenticacao();
        expect(r.dataOrNull?.pessoaId, 'pes_x');
      },
    );
  });

  group('Pessoas', () {
    setUp(() => backend.auth.entrarComo(usuarioAna));

    test('cadastra com criadoPor do usuário autenticado e id gerado', () async {
      final r = await pessoas.cadastrar(
        novaPessoa(nome: '  Maria  ', curso: 'tads', criadoPor: 'outro'),
      );
      final salva = r.dataOrNull!;
      expect(salva.id, isNotEmpty);
      expect(salva.nome, 'Maria');
      expect(salva.curso, 'TADS');
      expect(salva.criadoPor, usuarioAna.uid);
    });

    test('cadastro exige autenticação e dados válidos', () async {
      expect(
        erroDe(await pessoas.cadastrar(novaPessoa(turma: 1990))),
        contains('1998'),
      );
      backend.auth.logado = null;
      expect(
        erroDe(await pessoas.cadastrar(novaPessoa())),
        contains('autenticado'),
      );
    });

    test('busca, lista e altera mantendo o criador original', () async {
      final p = await cadastrar('Maria');
      backend.auth.entrarComo(usuarioJoao);

      final alterada = await pessoas.alterar(
        p.copyWith(apelido: 'Dudinha', criadoPor: usuarioJoao.uid),
      );
      expect(alterada.isSuccess, isTrue);
      expect((await pessoas.buscar(p.id)).dataOrNull?.apelido, 'Dudinha');
      expect(
        (await pessoas.buscar(p.id)).dataOrNull?.criadoPor,
        usuarioAna.uid,
      );
      expect((await pessoas.listar()).dataOrNull, hasLength(1));
    });

    test('remoção exige confirmação e só o criador pode remover', () async {
      final p = await cadastrar('Maria');

      expect(
        erroDe(await pessoas.remover(p.id, confirmado: false)),
        contains('confirmada'),
      );

      backend.auth.entrarComo(usuarioJoao);
      expect(
        erroDe(await pessoas.remover(p.id, confirmado: true)),
        contains('Somente quem cadastrou'),
      );

      backend.auth.entrarComo(usuarioAna);
      expect((await pessoas.remover(p.id, confirmado: true)).isSuccess, isTrue);
      expect((await pessoas.buscar(p.id)).dataOrNull, isNull);
    });

    test('erros do repositório viram Failure', () async {
      backend.pessoas.falhar = true;
      expect(erroDe(await pessoas.listar()), 'Servidor indisponível.');
    });
  });

  group('Avaliações', () {
    late PessoaModel maria;

    setUp(() async {
      backend.auth.entrarComo(usuarioAna);
      maria = await cadastrar('Maria');
    });

    test('quem cadastrou pode avaliar; pontuação total calculada', () async {
      final r = await avaliacoes.avaliar(
        pessoaId: maria.id,
        notas: notasExemploJoao,
      );
      expect(r.isSuccess, isTrue);
      final salva = backend.avaliacoes.dados['${usuarioAna.uid}_${maria.id}']!;
      expect(salva.pontuacaoTotal, 58);
      expect(salva.avaliadorUid, usuarioAna.uid);
      expect(salva.pessoaId, maria.id);
    });

    test('impede avaliação sem usuário autenticado', () async {
      backend.auth.logado = null;
      final r = await avaliacoes.avaliar(
        pessoaId: maria.id,
        notas: notasIguais(3),
      );
      expect(erroDe(r), contains('autenticado'));
      expect(backend.avaliacoes.dados, isEmpty);
    });

    test('impede autoavaliação da pessoa vinculada ao usuário', () async {
      expect((await auth.vincularPessoa(maria.id)).isSuccess, isTrue);

      final auto = await avaliacoes.verificarAutoavaliacao(maria.id);
      expect(auto.dataOrNull, isTrue);

      final r = await avaliacoes.avaliar(
        pessoaId: maria.id,
        notas: notasIguais(5),
      );
      expect(erroDe(r), contains('si próprio'));
      expect(backend.avaliacoes.dados, isEmpty);
    });

    test('impede notas menores que 1, maiores que 5 e incompletas', () async {
      for (final notas in [
        {...notasIguais(3), 'aura': 0},
        {...notasIguais(3), 'aura': 6},
        Map.of(notasIguais(3))..remove('resenha'),
      ]) {
        final r = await avaliacoes.avaliar(pessoaId: maria.id, notas: notas);
        expect(r.isFailure, isTrue);
      }
      expect(backend.avaliacoes.dados, isEmpty);
    });

    test('impede avaliação de pessoa inexistente', () async {
      final r = await avaliacoes.avaliar(
        pessoaId: 'nao_existe',
        notas: notasIguais(3),
      );
      expect(erroDe(r), contains('não encontrada'));
    });

    test(
      'uma avaliação por usuário e pessoa: segunda vez deve ser alteração',
      () async {
        await avaliacoes.avaliar(pessoaId: maria.id, notas: notasIguais(3));

        final duplicada = await avaliacoes.avaliar(
          pessoaId: maria.id,
          notas: notasIguais(5),
        );
        expect(erroDe(duplicada), contains('Altere a avaliação'));

        final alterada = await avaliacoes.alterarAvaliacao(
          pessoaId: maria.id,
          notas: notasIguais(5),
        );
        expect(alterada.dataOrNull?.pontuacaoTotal, 75);
        expect(backend.avaliacoes.dados, hasLength(1));

        final consulta = await avaliacoes.consultarAvaliacao(maria.id);
        expect(consulta.dataOrNull?.pontuacaoTotal, 75);
      },
    );

    test('alterar sem avaliação anterior falha', () async {
      final r = await avaliacoes.alterarAvaliacao(
        pessoaId: maria.id,
        notas: notasIguais(4),
      );
      expect(erroDe(r), contains('Nenhuma avaliação anterior'));
    });

    test('carrega apenas as avaliações do usuário autenticado', () async {
      await avaliacoes.avaliar(pessoaId: maria.id, notas: notasIguais(3));
      backend.auth.entrarComo(usuarioJoao);
      await avaliacoes.avaliar(pessoaId: maria.id, notas: notasIguais(4));

      final minhas = (await avaliacoes.carregarAvaliacoes()).dataOrNull!;
      expect(minhas, hasLength(1));
      expect(minhas.single.avaliadorUid, usuarioJoao.uid);
    });

    test('remover pessoa remove as avaliações recebidas', () async {
      await avaliacoes.avaliar(pessoaId: maria.id, notas: notasIguais(3));
      await pessoas.remover(maria.id, confirmado: true);
      expect(backend.avaliacoes.dados, isEmpty);
    });
  });

  group('Vínculo usuário × pessoa', () {
    setUp(() => backend.auth.entrarComo(usuarioAna));

    test('uma pessoa só pode estar vinculada a uma conta', () async {
      final maria = await cadastrar('Maria');
      expect((await auth.vincularPessoa(maria.id)).isSuccess, isTrue);

      backend.auth.entrarComo(usuarioJoao);
      expect(
        erroDe(await auth.vincularPessoa(maria.id)),
        contains('outra conta'),
      );
    });

    test('desvincular libera a autoavaliação bloqueada', () async {
      final maria = await cadastrar('Maria');
      await auth.vincularPessoa(maria.id);
      final r = await auth.vincularPessoa(null);
      expect(r.dataOrNull?.pessoaId, isNull);
      expect(
        (await avaliacoes.verificarAutoavaliacao(maria.id)).dataOrNull,
        isFalse,
      );
    });
  });

  group('Rankings', () {
    test(
      'ranking pessoal usa só as avaliações do usuário (exemplo do PDF)',
      () async {
        backend.auth.entrarComo(usuarioAna);
        final ana = await cadastrar('Ana Clara');
        final joao = await cadastrar('João Pedro');
        final maria = await cadastrar('Maria Eduarda');

        await avaliacoes.avaliar(pessoaId: joao.id, notas: notasComTotal(58));
        await avaliacoes.avaliar(pessoaId: maria.id, notas: notasComTotal(54));
        await avaliacoes.avaliar(pessoaId: ana.id, notas: notasComTotal(68));

        backend.auth.entrarComo(usuarioJoao);
        await avaliacoes.avaliar(pessoaId: maria.id, notas: notasComTotal(75));

        backend.auth.entrarComo(usuarioAna);
        final itens = (await ranking.gerarRankingPessoal()).dataOrNull!;
        expect(
          itens.map((i) => '${i.posicao}º ${i.pessoa.nome} – ${i.pontuacao}'),
          ['1º Ana Clara – 68', '2º João Pedro – 58', '3º Maria Eduarda – 54'],
        );
      },
    );

    test('ranking global usa a média das avaliações recebidas', () async {
      backend.auth.entrarComo(usuarioAna);
      final ana = await cadastrar('Ana');
      final joao = await cadastrar('João');
      await cadastrar('Sem Avaliação');

      final avaliadores = [
        usuarioAna,
        usuarioJoao,
        usuarioJoao.copyWith(uid: 'uid_3'),
      ];
      final notasAna = [60, 70, 65];
      for (var i = 0; i < 3; i++) {
        backend.auth.entrarComo(avaliadores[i]);
        await avaliacoes.avaliar(
          pessoaId: ana.id,
          notas: notasComTotal(notasAna[i]),
        );
      }
      await avaliacoes.avaliar(pessoaId: joao.id, notas: notasComTotal(66));

      final itens = (await ranking.gerarRankingGlobal()).dataOrNull!;
      expect(itens, hasLength(2), reason: 'quem não foi avaliado fica fora');
      expect(itens.first.pessoa.nome, 'João');
      expect(itens.first.mediaPontuacao, 66);
      expect(itens.last.pessoa.nome, 'Ana');
      expect(itens.last.mediaPontuacao, 65);
      expect(itens.last.totalAvaliacoes, 3);
      expect(itens.last.posicao, 2);
    });

    test('ranking pessoal exige autenticação', () async {
      expect((await ranking.gerarRankingPessoal()).isFailure, isTrue);
    });
  });

  group('Tema', () {
    test('salva e recupera a preferência de tema', () async {
      final tema = sl<TemaFacade>();
      expect((await tema.obterTemaSalvo()).dataOrNull, isNull);
      await tema.alterarTema(true);
      expect((await tema.obterTemaSalvo()).dataOrNull, isTrue);
      expect(backend.preferencias.temaEscuro, isTrue);
    });
  });
}
