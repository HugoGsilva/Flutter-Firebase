import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/core/router/app_router.dart';
import 'package:piramid_game/data/services/firestore_service.dart';
import 'package:piramid_game/firebase_options.dart';
import 'package:piramid_game/main.dart';
import 'package:piramid_game/presentation/viewmodels/auth_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/theme_viewmodel.dart';

/// Fluxo completo pela interface usando Firebase Authentication e Firestore
/// reais. Cria uma conta descartável e remove tudo ao final.
///
/// Requer os provedores "E-mail/senha" habilitados no Firebase Authentication.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final sufixo = DateTime.now().millisecondsSinceEpoch;
  final email = 'e2e.$sufixo@piramidgame.dev';
  const senha = 'senhaE2E123';
  final nomePessoa = 'E2E Pessoa $sufixo';

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signOut();
  });

  tearDownAll(() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInWithEmailAndPassword(email: email, password: senha);
      } on FirebaseAuthException {
        return;
      }
    }
    final uid = auth.currentUser!.uid;
    final firestore = FirestoreService();
    for (final p in await firestore.listarPessoas()) {
      if (p.criadoPor == uid) await firestore.removerPessoa(p.id);
    }
    await FirebaseFirestore.instance
        .collection(FirestoreService.colecaoUsuarios)
        .doc(uid)
        .delete();
    await auth.currentUser?.delete();
  });

  Future<void> abrirApp(WidgetTester tester) async {
    setupDependencies();
    await sl<ThemeViewModel>().carregarTemaCommand();
    await tester.pumpWidget(MainApp(router: criarRouter(sl<AuthViewModel>())));
    await esperar(
      tester,
      find.byType(NavigationBar),
      ouEntao: find.text('Entrar com Google'),
    );
  }

  testWidgets('cadastro, pessoa, avaliação, rankings e sessão', (tester) async {
    await abrirApp(tester);
    expect(find.text('Entrar com Google'), findsOneWidget);

    // Cadastro de usuário
    await tocar(tester, find.text('Criar conta'));
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Usuário E2E');
    await tester.enterText(campos.at(1), email);
    await tester.enterText(campos.at(2), senha);
    await tester.enterText(campos.at(3), senha);
    await tocar(tester, find.text('Cadastrar'));
    await esperar(tester, find.text('Nova Pessoa'), mensagemFalha: _snackBar);
    expect(FirebaseAuth.instance.currentUser?.email, email);

    // Cadastro de pessoa
    await tocar(tester, find.text('Nova Pessoa'));
    await tester.enterText(find.byKey(const Key('pessoa_nome')), nomePessoa);
    await tester.enterText(find.byKey(const Key('pessoa_apelido')), 'E2E');
    await tocar(tester, find.byKey(const Key('pessoa_nascimento')));
    await tocar(tester, find.text('OK'));
    await tocar(tester, find.text('Salvar Cadastro'));
    await esperar(tester, find.text(nomePessoa), mensagemFalha: _snackBar);

    // Avaliação
    await tocar(tester, find.text(nomePessoa));
    await tocar(tester, find.byKey(const Key('detalhe_avaliar')));
    await esperar(tester, find.text('1. Resenha'));
    await tocar(
      tester,
      find.descendant(
        of: find.byKey(const Key('estrelas_aura')),
        matching: find.byKey(const ValueKey('estrela_5')),
      ),
    );
    await tocar(tester, find.byKey(const Key('avaliacao_salvar')));
    await esperar(
      tester,
      find.text('Alterar Avaliação'),
      mensagemFalha: _snackBar,
    );

    // Rankings
    await tocar(tester, find.byTooltip('Voltar'));
    await tocar(tester, find.text('Ranking Pessoal'));
    await esperar(tester, find.text('47 pontos'));
    await tocar(tester, find.text('Ranking Global').last);
    await esperar(tester, find.text(nomePessoa));

    // Logout e novo login: dados continuam no Firestore
    await tocar(tester, find.byTooltip('Sair da conta'));
    await tocar(tester, find.text('Sair'));
    await esperar(tester, find.text('Entrar com Google'));

    await tester.enterText(find.byKey(const Key('login_email')), email);
    await tester.enterText(find.byKey(const Key('login_senha')), senha);
    await tocar(tester, find.text('Entrar'));
    await esperar(tester, find.text(nomePessoa), mensagemFalha: _snackBar);
    expect(find.text('47'), findsOneWidget);
  });

  testWidgets('sessão é restaurada ao reabrir o app', (tester) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
    }
    await abrirApp(tester);
    expect(find.text('Ranking Global'), findsWidgets);
    expect(find.text('Entrar com Google'), findsNothing);
  });

  testWidgets('senha errada mostra mensagem amigável', (tester) async {
    await FirebaseAuth.instance.signOut();
    await abrirApp(tester);
    await tester.enterText(find.byKey(const Key('login_email')), email);
    await tester.enterText(find.byKey(const Key('login_senha')), 'errada123');
    await tocar(tester, find.text('Entrar'));
    await esperar(tester, find.text('E-mail ou senha incorretos.'));
  });
}

/// Mensagens de snackbar vistas enquanto se espera algo aparecer na tela.
final _mensagensVistas = <String>{};

String _snackBar(WidgetTester tester) {
  return _mensagensVistas.isEmpty
      ? 'sem mensagem'
      : _mensagensVistas.join(' | ');
}

void _registrarSnackBars() {
  for (final e
      in find
          .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
          .evaluate()) {
    final texto = (e.widget as Text).data;
    if (texto != null) _mensagensVistas.add(texto);
  }
}

Future<void> esperar(
  WidgetTester tester,
  Finder alvo, {
  Finder? ouEntao,
  Duration limite = const Duration(seconds: 30),
  String Function(WidgetTester)? mensagemFalha,
}) async {
  _mensagensVistas.clear();
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 200));
    _registrarSnackBars();
    if (alvo.evaluate().isNotEmpty ||
        (ouEntao?.evaluate().isNotEmpty ?? false)) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Não apareceu: $alvo. Mensagens: ${_snackBar(tester)}');
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  await esperar(tester, alvo);
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(alvo.first);
  await tester.pumpAndSettle();
  await tester.tap(alvo.first);
  await tester.pumpAndSettle();
}
