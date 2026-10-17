import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/data/repositories/ranking_repository_impl.dart';
import 'package:piramid_game/domain/facades/auth_facade.dart';
import 'package:piramid_game/domain/facades/avaliacao_facade.dart';
import 'package:piramid_game/domain/facades/pessoa_facade.dart';
import 'package:piramid_game/domain/facades/ranking_facade.dart';
import 'package:piramid_game/domain/facades/tema_facade.dart';
import 'package:piramid_game/domain/models/avaliacao_model.dart';
import 'package:piramid_game/domain/models/pessoa_model.dart';
import 'package:piramid_game/domain/models/usuario_model.dart';
import 'package:piramid_game/domain/repositories/auth_repository.dart';
import 'package:piramid_game/domain/repositories/avaliacao_repository.dart';
import 'package:piramid_game/domain/repositories/pessoa_repository.dart';
import 'package:piramid_game/domain/repositories/preference_repository.dart';
import 'package:piramid_game/domain/usecases/auth/cadastrar_usuario_usecase.dart';
import 'package:piramid_game/domain/usecases/auth/login_email_usecase.dart';
import 'package:piramid_game/domain/usecases/auth/login_google_usecase.dart';
import 'package:piramid_game/domain/usecases/auth/logout_usecase.dart';
import 'package:piramid_game/domain/usecases/auth/verificar_autenticado_usecase.dart';
import 'package:piramid_game/domain/usecases/avaliacao/buscar_avaliacao_usuario_usecase.dart';
import 'package:piramid_game/domain/usecases/avaliacao/salvar_avaliacao_usecase.dart';
import 'package:piramid_game/domain/usecases/avaliacao/verificar_autoavaliacao_usecase.dart';
import 'package:piramid_game/domain/usecases/pessoa/atualizar_pessoa_usecase.dart';
import 'package:piramid_game/domain/usecases/pessoa/buscar_pessoa_por_id_usecase.dart';
import 'package:piramid_game/domain/usecases/pessoa/cadastrar_pessoa_usecase.dart';
import 'package:piramid_game/domain/usecases/pessoa/listar_pessoas_usecase.dart';
import 'package:piramid_game/domain/usecases/pessoa/remover_pessoa_usecase.dart';
import 'package:piramid_game/domain/usecases/ranking/calcular_ranking_global_usecase.dart';
import 'package:piramid_game/domain/usecases/ranking/calcular_ranking_pessoal_usecase.dart';
import 'package:piramid_game/domain/usecases/tema/obter_tema_salvo_usecase.dart';
import 'package:piramid_game/domain/usecases/tema/salvar_tema_usecase.dart';
import 'package:piramid_game/presentation/viewmodels/auth_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/avaliacao_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/home_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/pessoa_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/theme_viewmodel.dart';
import 'package:piramid_game/presentation/views/auth/login_screen.dart';
import 'package:piramid_game/presentation/views/auth/register_screen.dart';
import 'package:piramid_game/presentation/views/avaliacao/avaliacao_screen.dart';
import 'package:piramid_game/presentation/views/avaliacao/widgets/star_rating.dart';
import 'package:piramid_game/presentation/views/home/home_screen.dart';
import 'package:piramid_game/presentation/views/pessoas/pessoa_detail_screen.dart';
import 'package:piramid_game/presentation/views/pessoas/pessoa_form_screen.dart';
import 'package:piramid_game/presentation/views/pessoas/pessoas_list_view.dart';
import 'package:piramid_game/presentation/views/ranking/ranking_global_view.dart';
import 'package:piramid_game/presentation/views/ranking/ranking_pessoal_view.dart';
import 'package:piramid_game/presentation/views/sobre/sobre_view.dart';
import 'package:piramid_game/presentation/views/splash/splash_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  UsuarioModel? _user = const UsuarioModel(
    uid: 'uid_1',
    nome: 'Aluno Teste',
    email: 'teste@ifpr.edu.br',
    provider: 'password',
  );

  @override
  UsuarioModel? get usuarioAtual => _user;

  @override
  Stream<UsuarioModel?> get authStateChanges => Stream.value(_user);

  @override
  Future<UsuarioModel> cadastrarComEmail({
    required String nome,
    required String email,
    required String senha,
  }) async {
    _user = UsuarioModel(
      uid: 'uid_novo',
      nome: nome,
      email: email,
      provider: 'password',
    );
    return _user!;
  }

  @override
  Future<UsuarioModel> loginComEmail({
    required String email,
    required String senha,
  }) async {
    _user = UsuarioModel(
      uid: 'uid_1',
      nome: 'Aluno Teste',
      email: email,
      provider: 'password',
    );
    return _user!;
  }

  @override
  Future<UsuarioModel> loginComGoogle() async {
    _user = const UsuarioModel(
      uid: 'uid_google',
      nome: 'Google User',
      email: 'google@gmail.com',
      provider: 'google.com',
    );
    return _user!;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }
}

class _FakePessoaRepository implements PessoaRepository {
  final List<PessoaModel> _pessoas = [
    PessoaModel(
      id: 'p1',
      nome: 'Ioshi IFPR',
      apelido: 'Ioshi',
      curso: 'INFO',
      turma: 2026,
      dataNascimento: DateTime(2007, 5, 20),
      criadoPor: 'outro_uid',
    ),
    PessoaModel(
      id: 'p2',
      nome: 'Mounir Veterano',
      apelido: 'Mounir',
      curso: 'TADS',
      turma: 2024,
      dataNascimento: DateTime(2003, 3, 10),
      criadoPor: 'uid_1',
    ),
  ];

  @override
  Future<void> cadastrarPessoa(PessoaModel pessoa) async {
    _pessoas.add(pessoa);
  }

  @override
  Future<void> atualizarPessoa(PessoaModel pessoa) async {
    final idx = _pessoas.indexWhere((p) => p.id == pessoa.id);
    if (idx != -1) {
      _pessoas[idx] = pessoa;
    }
  }

  @override
  Future<void> removerPessoa(String id) async {
    _pessoas.removeWhere((p) => p.id == id);
  }

  @override
  Future<PessoaModel?> buscarPorId(String id) async {
    try {
      return _pessoas.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PessoaModel>> listarTodas() async => List.unmodifiable(_pessoas);
}

class _FakeAvaliacaoRepository implements AvaliacaoRepository {
  final Map<String, AvaliacaoModel> _avaliacoes = {};

  @override
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {
    _avaliacoes[avaliacao.id] = avaliacao;
  }

  @override
  Future<AvaliacaoModel?> buscarAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async {
    final id = AvaliacaoModel.gerarIdCanonico(avaliadorUid, pessoaId);
    return _avaliacoes[id];
  }

  @override
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId) async {
    return _avaliacoes.values.where((a) => a.pessoaId == pessoaId).toList();
  }

  @override
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid) async {
    return _avaliacoes.values
        .where((a) => a.avaliadorUid == avaliadorUid)
        .toList();
  }

  @override
  Future<List<AvaliacaoModel>> listarTodas() async {
    return _avaliacoes.values.toList();
  }
}

class _FakePreferenceRepository implements PreferenceRepository {
  bool? _isDark = false;
  String? _ultimoUid;

  @override
  Future<void> salvarTemaEscuro(bool isDark) async {
    _isDark = isDark;
  }

  @override
  Future<bool?> obterTemaEscuro() async => _isDark;

  @override
  Future<void> salvarUltimoUid(String uid) async {
    _ultimoUid = uid;
  }

  @override
  Future<String?> obterUltimoUid() async => _ultimoUid;

  @override
  Future<void> limparSessao() async {
    _ultimoUid = null;
  }
}

void _setupTestLocator() {
  sl.reset();

  final authRepo = _FakeAuthRepository();
  final pessoaRepo = _FakePessoaRepository();
  final avaliacaoRepo = _FakeAvaliacaoRepository();
  final prefRepo = _FakePreferenceRepository();
  final rankingRepo = RankingRepositoryImpl(pessoaRepo, avaliacaoRepo);

  final authFacade = AuthFacade(
    cadastrarUsuarioUseCase: CadastrarUsuarioUseCase(authRepo),
    loginEmailUseCase: LoginEmailUseCase(authRepo),
    loginGoogleUseCase: LoginGoogleUseCase(authRepo),
    logoutUseCase: LogoutUseCase(authRepo),
    verificarAutenticadoUseCase: VerificarAutenticadoUseCase(authRepo),
  );

  final avaliacaoFacade = AvaliacaoFacade(
    salvarAvaliacaoUseCase: SalvarAvaliacaoUseCase(avaliacaoRepo),
    buscarAvaliacaoUsuarioUseCase: BuscarAvaliacaoUsuarioUseCase(avaliacaoRepo),
    verificarAutoavaliacaoUseCase: const VerificarAutoavaliacaoUseCase(),
  );

  final pessoaFacade = PessoaFacade(
    cadastrarPessoaUseCase: CadastrarPessoaUseCase(pessoaRepo),
    atualizarPessoaUseCase: AtualizarPessoaUseCase(pessoaRepo),
    removerPessoaUseCase: RemoverPessoaUseCase(pessoaRepo),
    listarPessoasUseCase: ListarPessoasUseCase(pessoaRepo),
    buscarPessoaPorIdUseCase: BuscarPessoaPorIdUseCase(pessoaRepo),
  );

  final rankingFacade = RankingFacade(
    calcularRankingPessoalUseCase: CalcularRankingPessoalUseCase(rankingRepo),
    calcularRankingGlobalUseCase: CalcularRankingGlobalUseCase(rankingRepo),
  );

  final temaFacade = TemaFacade(
    obterTemaSalvoUseCase: ObterTemaSalvoUseCase(prefRepo),
    salvarTemaUseCase: SalvarTemaUseCase(prefRepo),
  );

  sl.registerSingleton<AuthViewModel>(AuthViewModel(authFacade));
  sl.registerSingleton<PessoaViewModel>(PessoaViewModel(pessoaFacade));
  sl.registerSingleton<AvaliacaoViewModel>(AvaliacaoViewModel(avaliacaoFacade));
  sl.registerSingleton<RankingViewModel>(RankingViewModel(rankingFacade, authFacade: authFacade));
  sl.registerSingleton<ThemeViewModel>(ThemeViewModel(temaFacade));
  sl.registerSingleton<HomeViewModel>(HomeViewModel());
}

void main() {
  setUp(() {
    _setupTestLocator();
  });

  group('Presentation Views Tests', () {
    testWidgets('SplashScreen exibe título, subtítulo e identificação IFPR', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashScreen()),
      );

      expect(find.text('PiramidGame IFPR-Pgua'), findsOneWidget);
      expect(find.text('IFPR - Campus Paranaguá'), findsOneWidget);
      expect(find.text('Ranking de Popularidade e Nível Lenda no Campus'), findsOneWidget);
    });

    testWidgets('LoginScreen renderiza campos de e-mail, senha e botões', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      expect(find.text('PiramidGame IFPR-Pgua'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Entrar com Google'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
    });

    testWidgets('RegisterScreen renderiza campos e validação de senhas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      expect(find.text('Criar Nova Conta'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('Cadastrar'), findsOneWidget);

      await tester.tap(find.text('Cadastrar'));
      await tester.pump();

      expect(find.text('Informe seu nome'), findsOneWidget);
    });

    testWidgets('HomeScreen exibe AppBar e todas as 4 abas de navegação', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.text('Piramid Game'), findsOneWidget);
      expect(find.text('Pessoas'), findsOneWidget);
      expect(find.text('Ranking Pessoal'), findsOneWidget);
      expect(find.text('Ranking Global'), findsOneWidget);
      expect(find.text('Sobre o App'), findsOneWidget);
    });

    testWidgets('SobreView exibe o texto oficial sugerido da página 20 e os 15 critérios', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SobreView()),
      );

      expect(find.text('PiramidGame IFPR-Pgua'), findsOneWidget);
      expect(find.text('IFPR – Campus Paranaguá'), findsOneWidget);
      expect(
        find.textContaining(
          'O PiramidGame IFPR-Pgua é um aplicativo desenvolvido em Flutter para fins didáticos',
        ),
        findsOneWidget,
      );
      expect(find.text('Cálculo do Nível Lenda'), findsOneWidget);
      expect(find.text('Rankings Pessoal e Global'), findsOneWidget);
      expect(find.text('Os 15 Critérios de Avaliação'), findsOneWidget);
    });

    testWidgets('StarRating renderiza estrelas e reage ao toque', (tester) async {
      int notaEscolhida = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(
              rating: 3,
              onRatingChanged: (val) {
                notaEscolhida = val;
              },
            ),
          ),
        ),
      );

      final inkResponses = find.byType(InkResponse);
      expect(inkResponses, findsNWidgets(5));

      await tester.tap(inkResponses.at(4));
      await tester.pump();

      expect(notaEscolhida, equals(5));
    });

    testWidgets('AvaliacaoScreen exibe critérios e Nível Lenda dinâmico', (tester) async {
      final pessoa = PessoaModel(
        id: 'p1',
        nome: 'Ioshi IFPR',
        apelido: 'Ioshi',
        curso: 'INFO',
        turma: 2026,
        dataNascimento: DateTime(2007, 5, 20),
        criadoPor: 'outro_uid',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AvaliacaoScreen(pessoaId: 'p1', pessoa: pessoa),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Avaliar Ioshi'), findsOneWidget);
      expect(find.text('Nível Lenda'), findsOneWidget);
      expect(find.text('Resenha'), findsOneWidget);
      expect(find.text('Presença VIP'), findsOneWidget);
      expect(find.text('Salvar Avaliação'), findsOneWidget);
    });

    testWidgets('AvaliacaoScreen bloqueia autoavaliação quando usuário tenta avaliar seu próprio cadastro', (tester) async {
      final pessoaPropria = PessoaModel(
        id: 'p2',
        nome: 'Mounir Veterano',
        apelido: 'Mounir',
        curso: 'TADS',
        turma: 2024,
        dataNascimento: DateTime(2003, 3, 10),
        criadoPor: 'uid_1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AvaliacaoScreen(pessoaId: 'p2', pessoa: pessoaPropria),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Autoavaliação Bloqueada'), findsOneWidget);
      expect(
        find.textContaining('Pelas regras do PiramidGame, um usuário não pode avaliar o próprio perfil'),
        findsOneWidget,
      );
      expect(find.text('Salvar Avaliação'), findsNothing);
    });

    testWidgets('PessoaFormScreen valida formulário e salva cadastro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PessoaFormScreen()),
      );

      expect(find.text('Cadastrar Pessoa'), findsOneWidget);
      expect(find.text('Salvar Cadastro'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Luizinho IFPR');
      await tester.enterText(find.byType(TextFormField).at(1), 'Luizinho');

      await tester.tap(find.text('Salvar Cadastro'));
      await tester.pumpAndSettle();

      final pessoaVm = sl<PessoaViewModel>();
      expect(pessoaVm.pessoas.value.any((p) => p.nome == 'Luizinho IFPR'), isTrue);
    });

    testWidgets('PessoasListView permite busca e exibe pessoas da lista', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PessoasListView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ioshi IFPR'), findsOneWidget);
      expect(find.text('Mounir Veterano'), findsOneWidget);
      expect(find.text('Nova Pessoa'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Ioshi');
      await tester.pumpAndSettle();

      expect(find.text('Ioshi IFPR'), findsOneWidget);
      expect(find.text('Mounir Veterano'), findsNothing);
    });

    testWidgets('PessoaDetailScreen exibe informações e diálogo de exclusão', (tester) async {
      final pessoa = PessoaModel(
        id: 'p1',
        nome: 'Ioshi IFPR',
        apelido: 'Ioshi',
        curso: 'INFO',
        turma: 2026,
        dataNascimento: DateTime(2007, 5, 20),
        criadoPor: 'outro_uid',
      );

      await tester.pumpWidget(
        MaterialApp(home: PessoaDetailScreen(pessoaId: 'p1', pessoa: pessoa)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ioshi'), findsAtLeast(1));
      expect(find.text('Ioshi IFPR'), findsOneWidget);
      expect(find.text('Avaliar Pessoa'), findsOneWidget);
      expect(find.text('Editar Cadastro'), findsOneWidget);
      await tester.ensureVisible(find.text('Excluir Cadastro'));
      await tester.tap(find.text('Excluir Cadastro'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar exclusão'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('RankingPessoalView exibe título e pergunta norteadora', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RankingPessoalView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ranking Pessoal'), findsOneWidget);
      expect(find.text('“Na minha opinião, quem possui o maior Nível Lenda?”'), findsOneWidget);
    });

    testWidgets('RankingGlobalView exibe título e pergunta norteadora', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RankingGlobalView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ranking Global'), findsOneWidget);
      expect(find.text('“Na opinião dos usuários do aplicativo, quem possui o maior Nível Lenda?”'), findsOneWidget);
    });
  });
}
