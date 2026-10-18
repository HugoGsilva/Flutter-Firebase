import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/core/result/app_exception.dart';
import 'package:piramid_game/data/services/firestore_service.dart';
import 'package:piramid_game/domain/facades/avaliacao_facade.dart';
import 'package:piramid_game/domain/facades/pessoa_facade.dart';
import 'package:piramid_game/domain/facades/ranking_facade.dart';
import 'package:piramid_game/domain/models/usuario_model.dart';
import 'package:piramid_game/firebase_options.dart';

import 'support/fakes.dart';

/// Executa os use cases reais contra o Firestore do projeto. Só a
/// autenticação é simulada; pessoas e avaliações vão para o banco de verdade.
///
/// Por padrão apaga tudo o que criou. Com
/// `--dart-define=MANTER_DADOS=true` os documentos ficam no Firestore para
/// conferência manual.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const manterDados = bool.fromEnvironment('MANTER_DADOS');
  final sufixo = DateTime.now().millisecondsSinceEpoch;
  final avaliador1 = UsuarioModel(
    uid: 'e2e_avaliador1_$sufixo',
    nome: 'Avaliador E2E 1',
    email: 'e2e1@teste.dev',
    provider: 'password',
  );
  final avaliador2 = UsuarioModel(
    uid: 'e2e_avaliador2_$sufixo',
    nome: 'Avaliador E2E 2',
    email: 'e2e2@teste.dev',
    provider: 'password',
  );

  late FakeAuthRepository auth;
  late FirestoreService firestore;
  final pessoasCriadas = <String>[];

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FakeAuthRepository();
    setupDependencies(
      authRepository: auth,
      preferenceRepository: FakePreferenceRepository(),
    );
    firestore = sl<FirestoreService>();
  });

  tearDownAll(() async {
    if (manterDados) {
      // ignore: avoid_print
      print('E2E_PESSOAS=${pessoasCriadas.join(',')}');
      return;
    }
    for (final id in pessoasCriadas) {
      await firestore.removerPessoa(id);
    }
  });

  testWidgets('CRUD, avaliações e rankings persistidos no Firestore', (
    _,
  ) async {
    final pessoas = sl<PessoaFacade>();
    final avaliacoes = sl<AvaliacaoFacade>();
    final ranking = sl<RankingFacade>();

    // Cadastro de pessoas
    auth.entrarComo(avaliador1);
    final ana = (await pessoas.cadastrar(
      novaPessoa(nome: 'E2E Ana Clara', apelido: 'Aninha', curso: 'TADS'),
    )).dataOrNull!;
    final joao = (await pessoas.cadastrar(
      novaPessoa(nome: 'E2E João Pedro', apelido: 'Jota', curso: 'INFO'),
    )).dataOrNull!;
    final temp = (await pessoas.cadastrar(
      novaPessoa(nome: 'E2E Temporário', apelido: 'Temp', curso: 'MEC'),
    )).dataOrNull!;
    pessoasCriadas.addAll([ana.id, joao.id, temp.id]);

    expect(ana.id, isNotEmpty);
    final lida = await firestore.obterPessoa(ana.id);
    expect(lida?.nome, 'E2E Ana Clara');
    expect(lida?.curso, 'TADS');
    expect(lida?.turma, 2024);
    expect(lida?.criadoPor, avaliador1.uid);

    // Alteração
    final alterada = await pessoas.alterar(ana.copyWith(apelido: 'Ana Lenda'));
    expect(alterada.isSuccess, isTrue);
    expect((await firestore.obterPessoa(ana.id))?.apelido, 'Ana Lenda');

    // Avaliações do avaliador 1
    expect(
      (await avaliacoes.avaliar(
        pessoaId: ana.id,
        notas: notasComTotal(60),
      )).isSuccess,
      isTrue,
    );
    expect(
      (await avaliacoes.avaliar(
        pessoaId: joao.id,
        notas: notasExemploJoao,
      )).isSuccess,
      isTrue,
    );

    // Mesma pessoa duas vezes não cria outra avaliação
    final duplicada = await avaliacoes.avaliar(
      pessoaId: ana.id,
      notas: notasComTotal(75),
    );
    expect(duplicada.isFailure, isTrue);

    // Avaliador 2 está vinculado ao João: não pode se avaliar
    auth.entrarComo(avaliador2);
    await auth.vincularPessoa(avaliador2.uid, joao.id);
    final auto = await avaliacoes.avaliar(
      pessoaId: joao.id,
      notas: notasIguais(5),
    );
    expect(mensagemDoErro(auto.errorOrNull!), contains('si próprio'));

    await avaliacoes.avaliar(pessoaId: ana.id, notas: notasComTotal(65));
    await avaliacoes.avaliar(pessoaId: temp.id, notas: notasIguais(5));

    // Avaliador 2 muda de opinião sobre a Ana
    final alterarAna = await avaliacoes.alterarAvaliacao(
      pessoaId: ana.id,
      notas: notasComTotal(70),
    );
    expect(alterarAna.isSuccess, isTrue);

    // Documento gravado com um campo por critério
    final doc = await firestore.obterAvaliacao(avaliador1.uid, joao.id);
    expect(doc?.pontuacaoTotal, 58);
    expect(doc?.notas['aura'], 5);
    expect(doc?.notas['talentoDePalco'], 2);
    expect(doc?.id, '${avaliador1.uid}_${joao.id}');

    // Ranking pessoal do avaliador 2: só as notas dele
    final pessoal = (await ranking.gerarRankingPessoal()).dataOrNull!;
    expect(pessoal.map((i) => i.pessoa.id), [temp.id, ana.id]);
    expect(pessoal.map((i) => i.pontuacao), [75, 70]);

    // Ranking global: Ana = (60 + 70) / 2 = 65
    final global = (await ranking.gerarRankingGlobal()).dataOrNull!;
    final itemAna = global.firstWhere((i) => i.pessoa.id == ana.id);
    expect(itemAna.mediaPontuacao, 65);
    expect(itemAna.totalAvaliacoes, 2);
    final itemJoao = global.firstWhere((i) => i.pessoa.id == joao.id);
    expect(itemJoao.mediaPontuacao, 58);
    expect(itemJoao.totalAvaliacoes, 1);

    // Remoção: só o criador remove, e as avaliações recebidas vão junto
    final semPermissao = await pessoas.remover(temp.id, confirmado: true);
    expect(semPermissao.isFailure, isTrue);

    auth.entrarComo(avaliador1);
    expect(
      (await pessoas.remover(temp.id, confirmado: true)).isSuccess,
      isTrue,
    );
    pessoasCriadas.remove(temp.id);
    expect(await firestore.obterPessoa(temp.id), isNull);
    expect(await firestore.listarAvaliacoesPorPessoa(temp.id), isEmpty);
  });

  testWidgets('coleção usuarios guarda perfil e vínculo com a pessoa', (
    _,
  ) async {
    final usuario = avaliador1;
    await firestore.salvarUsuario(usuario);
    await firestore.atualizarPessoaVinculada(usuario.uid, 'pessoa_teste');

    final perfil = await firestore.obterUsuario(usuario.uid);
    expect(perfil?.email, usuario.email);
    expect(perfil?.pessoaId, 'pessoa_teste');
    expect(
      (await firestore.buscarUsuarioPorPessoa('pessoa_teste'))?.uid,
      usuario.uid,
    );

    // Salvar o perfil novamente não apaga o vínculo
    await firestore.salvarUsuario(usuario.copyWith(nome: 'Outro Nome'));
    expect(
      (await firestore.obterUsuario(usuario.uid))?.pessoaId,
      'pessoa_teste',
    );

    await firestore.atualizarPessoaVinculada(usuario.uid, null);
    expect((await firestore.obterUsuario(usuario.uid))?.pessoaId, isNull);
  });
}
