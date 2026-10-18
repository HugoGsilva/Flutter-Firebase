import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/core/router/app_router.dart';
import 'package:piramid_game/main.dart';
import 'package:piramid_game/presentation/viewmodels/auth_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/theme_viewmodel.dart';

import '../../integration_test/support/fakes.dart';

/// Percorre o app inteiro usando o router real e repositórios em memória.
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

  Future<void> abrirApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MainApp(router: criarRouter(sl<AuthViewModel>())));
    expect(find.text('PiramidGame IFPR-Pgua'), findsOneWidget);
    expect(find.text('IFPR – Campus Paranaguá'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    // Aguarda snackbars anteriores saírem para não cobrirem o alvo.
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  testWidgets('sem sessão a splash leva para o login', (tester) async {
    await abrirApp(tester);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('com sessão válida a splash vai direto para a home', (
    tester,
  ) async {
    backend.auth.entrarComo(usuarioAna);
    await abrirApp(tester);
    expect(find.text('Pessoas'), findsWidgets);
    expect(find.text('Ranking Global'), findsWidgets);
  });

  testWidgets('erro de login é exibido ao usuário', (tester) async {
    await abrirApp(tester);
    await tester.enterText(find.byKey(const Key('login_email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('login_senha')), 'errada1');
    await tocar(tester, find.text('Entrar'));
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets(
    'fluxo completo: conta, pessoa, avaliação, rankings, tema e logout',
    (tester) async {
      await abrirApp(tester);

      // Cadastro de usuário
      await tocar(tester, find.text('Criar conta'));
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Ana Clara');
      await tester.enterText(campos.at(1), 'ana@ifpr.edu.br');
      await tester.enterText(campos.at(2), '123456');
      await tester.enterText(campos.at(3), '123456');
      await tocar(tester, find.text('Cadastrar'));
      expect(find.text('Nenhuma pessoa encontrada'), findsOneWidget);

      // Cadastro de pessoa
      await tocar(tester, find.text('Nova Pessoa'));
      await tester.enterText(
        find.byKey(const Key('pessoa_nome')),
        'João Pedro',
      );
      await tester.enterText(find.byKey(const Key('pessoa_apelido')), 'Jota');
      await tocar(tester, find.byKey(const Key('pessoa_curso')));
      await tocar(tester, find.text('TADS').last);
      await tocar(tester, find.byKey(const Key('pessoa_nascimento')));
      await tocar(tester, find.text('OK'));
      await tocar(tester, find.text('Salvar Cadastro'));

      expect(find.text('João Pedro'), findsOneWidget);
      expect(find.text('TADS'), findsWidgets);
      final pessoa = backend.pessoas.dados.values.single;
      expect(pessoa.curso, 'TADS');
      expect(pessoa.criadoPor, backend.auth.logado!.uid);

      // Detalhes e avaliação (quem cadastrou pode avaliar)
      await tocar(tester, find.text('João Pedro'));
      expect(find.text('Seu Nível Lenda'), findsOneWidget);
      await tocar(tester, find.byKey(const Key('detalhe_avaliar')));
      expect(find.text('1. Resenha'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);

      final estrelasAura = find.descendant(
        of: find.byKey(const Key('estrelas_aura')),
        matching: find.byKey(const ValueKey('estrela_5')),
      );
      await tocar(tester, estrelasAura);
      expect(find.text('47'), findsOneWidget);

      await tocar(tester, find.byKey(const Key('avaliacao_salvar')));
      expect(backend.avaliacoes.dados.values.single.pontuacaoTotal, 47);
      expect(find.text('Alterar Avaliação'), findsOneWidget);

      // Voltar para a lista mostra o Nível Lenda dado
      await tocar(tester, find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('47'), findsOneWidget);

      // Rankings
      await tocar(tester, find.text('Ranking Pessoal'));
      expect(
        find.text('“Na minha opinião, quem possui o maior Nível Lenda?”'),
        findsOneWidget,
      );
      expect(find.text('47 pontos'), findsOneWidget);

      await tocar(tester, find.text('Ranking Global').last);
      expect(find.text('47,0 pontos'), findsOneWidget);
      expect(find.text('1 avaliação'), findsOneWidget);

      // Sobre
      await tocar(tester, find.text('Sobre'));
      expect(find.textContaining('Firebase Authentication'), findsWidgets);

      // Tema
      expect(sl<ThemeViewModel>().isDarkMode.value, isFalse);
      await tocar(tester, find.byTooltip('Ativar tema escuro'));
      expect(sl<ThemeViewModel>().isDarkMode.value, isTrue);
      expect(backend.preferencias.temaEscuro, isTrue);

      // Logout
      await tocar(tester, find.byTooltip('Sair da conta'));
      await tocar(tester, find.text('Sair'));
      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(backend.auth.logado, isNull);
      expect(backend.preferencias.cache, isNull);
    },
  );

  testWidgets('pessoa vinculada ao usuário não pode ser avaliada', (
    tester,
  ) async {
    backend.auth.entrarComo(usuarioAna);
    await abrirApp(tester);

    await tocar(tester, find.text('Nova Pessoa'));
    await tester.enterText(find.byKey(const Key('pessoa_nome')), 'Ana Clara');
    await tester.enterText(find.byKey(const Key('pessoa_apelido')), 'Aninha');
    await tocar(tester, find.byKey(const Key('pessoa_nascimento')));
    await tocar(tester, find.text('OK'));
    await tocar(tester, find.byKey(const Key('pessoa_sou_eu')));
    await tocar(tester, find.text('Salvar Cadastro'));

    final pessoa = backend.pessoas.dados.values.single;
    expect(backend.auth.perfis[usuarioAna.uid]?.pessoaId, pessoa.id);
    expect(find.text('Você'), findsOneWidget);

    await tocar(tester, find.text('Ana Clara'));
    expect(
      find.textContaining('não é permitida autoavaliação'),
      findsOneWidget,
    );
    final botao = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Avaliar Pessoa'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(botao.onPressed, isNull);

    // Acessando a rota diretamente também é bloqueado
    final context = tester.element(find.byType(Scaffold).last);
    GoRouter.of(context).push(AppRoutes.avaliar(pessoa.id));
    await tester.pumpAndSettle();
    expect(find.text('Autoavaliação bloqueada'), findsOneWidget);
  });

  testWidgets('excluir pessoa pede confirmação', (tester) async {
    backend.auth.entrarComo(usuarioAna);
    await backend.pessoas.cadastrarPessoa(novaPessoa(nome: 'Bruno'));
    await abrirApp(tester);

    await tocar(tester, find.text('Bruno'));
    await tocar(tester, find.text('Excluir Cadastro'));
    expect(find.text('Confirmar exclusão'), findsOneWidget);
    await tocar(tester, find.text('Cancelar'));
    expect(backend.pessoas.dados, hasLength(1));

    await tocar(tester, find.text('Excluir Cadastro'));
    await tocar(tester, find.text('Excluir'));
    expect(backend.pessoas.dados, isEmpty);
    expect(find.text('Nenhuma pessoa encontrada'), findsOneWidget);
  });

  testWidgets('pessoa cadastrada por outro usuário não mostra excluir', (
    tester,
  ) async {
    backend.auth.entrarComo(usuarioJoao);
    await backend.pessoas.cadastrarPessoa(novaPessoa(nome: 'Bruno'));
    await abrirApp(tester);

    await tocar(tester, find.text('Bruno'));
    expect(find.text('Excluir Cadastro'), findsNothing);
    expect(find.text('Outro usuário'), findsOneWidget);
    expect(find.text('Editar Cadastro'), findsOneWidget);
  });
}
