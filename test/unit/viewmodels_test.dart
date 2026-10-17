import 'package:flutter_test/flutter_test.dart';
import 'package:piramid_game/core/command/command.dart';
import 'package:piramid_game/core/di/injection.dart';
import 'package:piramid_game/core/result/result.dart';
import 'package:piramid_game/data/repositories/ranking_repository_impl.dart';
import 'package:piramid_game/domain/facades/auth_facade.dart';
import 'package:piramid_game/domain/facades/avaliacao_facade.dart';
import 'package:piramid_game/domain/facades/pessoa_facade.dart';
import 'package:piramid_game/domain/facades/ranking_facade.dart';
import 'package:piramid_game/domain/facades/tema_facade.dart';
import 'package:piramid_game/domain/models/avaliacao_model.dart';
import 'package:piramid_game/domain/models/criterios_avaliacao.dart';
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
import 'package:piramid_game/presentation/viewmodels/pessoa_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:piramid_game/presentation/viewmodels/theme_viewmodel.dart';

// --- Fakes para testes unitários isolados ---

class FakeAuthRepository implements AuthRepository {
  UsuarioModel? _user;

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
    if (senha.length < 6) {
      throw Exception('A senha deve ter pelo menos 6 caracteres.');
    }
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
    if (email == 'invalido@email.com') {
      throw Exception('Credenciais inválidas.');
    }
    _user = UsuarioModel(
      uid: 'uid_logado',
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

class FakePessoaRepository implements PessoaRepository {
  final List<PessoaModel> _pessoas = [];

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

class FakeAvaliacaoRepository implements AvaliacaoRepository {
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

class FakePreferenceRepository implements PreferenceRepository {
  bool? _isDark;
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

void main() {
  group('Command Tests', () {
    test(
      'Command0 deve gerenciar estado running, resultado e signal',
      () async {
        final cmd = Command0<String>(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return const Success('ok');
        });

        expect(cmd.running, isFalse);
        expect(cmd.runningSignal.value, isFalse);
        expect(cmd.completed, isFalse);

        final future = cmd.execute();
        expect(cmd.running, isTrue);
        expect(cmd.runningSignal.value, isTrue);

        final res = await future;
        expect(res.dataOrNull, 'ok');
        expect(cmd.running, isFalse);
        expect(cmd.completed, isTrue);
        expect(cmd.result?.dataOrNull, 'ok');
      },
    );

    test(
      'Command callable deve permitir invocação direta como função',
      () async {
        final cmd = Command1<int, int>((val) async => Success(val * 2));
        final res = await cmd(5);
        expect(res.dataOrNull, 10);
      },
    );
  });

  group('AuthViewModel Tests', () {
    late FakeAuthRepository authRepo;
    late AuthFacade authFacade;
    late AuthViewModel viewModel;

    setUp(() {
      authRepo = FakeAuthRepository();
      authFacade = AuthFacade(
        cadastrarUsuarioUseCase: CadastrarUsuarioUseCase(authRepo),
        loginEmailUseCase: LoginEmailUseCase(authRepo),
        loginGoogleUseCase: LoginGoogleUseCase(authRepo),
        logoutUseCase: LogoutUseCase(authRepo),
        verificarAutenticadoUseCase: VerificarAutenticadoUseCase(authRepo),
      );
      viewModel = AuthViewModel(authFacade);
    });

    test('deve iniciar desautenticado', () {
      expect(viewModel.currentUser.value, isNull);
      expect(viewModel.isAuthenticated.value, isFalse);
      expect(viewModel.isLoading.value, isFalse);
      expect(viewModel.errorMessage.value, isNull);
    });

    test('deve autenticar com sucesso no loginCommand', () async {
      final res = await viewModel.loginCommand('aluno@escola.com', '123456');

      expect(res.isSuccess, isTrue);
      expect(viewModel.currentUser.value?.email, 'aluno@escola.com');
      expect(viewModel.isAuthenticated.value, isTrue);
      expect(viewModel.errorMessage.value, isNull);
      expect(viewModel.isLoading.value, isFalse);
    });

    test(
      'deve capturar erro e atualizar errorMessage em falha de login',
      () async {
        final res = await viewModel.loginCommand(
          'invalido@email.com',
          '123456',
        );

        expect(res.isFailure, isTrue);
        expect(viewModel.currentUser.value, isNull);
        expect(viewModel.isAuthenticated.value, isFalse);
        expect(viewModel.errorMessage.value, contains('Credenciais inválidas'));
      },
    );

    test('deve cadastrar com sucesso no cadastroCommand', () async {
      final res = await viewModel.cadastroCommand(
        'novo@escola.com',
        '123456',
        'Novo Aluno',
      );

      expect(res.isSuccess, isTrue);
      expect(viewModel.currentUser.value?.nome, 'Novo Aluno');
      expect(viewModel.isAuthenticated.value, isTrue);
    });

    test('deve logar com Google e deslogar com logoutCommand', () async {
      await viewModel.loginGoogleCommand();
      expect(viewModel.isAuthenticated.value, isTrue);
      expect(viewModel.currentUser.value?.provider, 'google.com');

      await viewModel.logoutCommand();
      expect(viewModel.currentUser.value, isNull);
      expect(viewModel.isAuthenticated.value, isFalse);
    });
  });

  group('PessoaViewModel Tests', () {
    late FakePessoaRepository pessoaRepo;
    late PessoaFacade pessoaFacade;
    late PessoaViewModel viewModel;

    final pessoa1 = PessoaModel(
      id: 'p1',
      nome: 'Carlos Drummond',
      apelido: 'Poeta',
      curso: 'INFO',
      turma: 2024,
      dataNascimento: DateTime(2005, 5, 10),
      criadoPor: 'uid_criador_1',
    );

    final pessoa2 = PessoaModel(
      id: 'p2',
      nome: 'Ana Machado',
      apelido: 'Aninha',
      curso: 'MEC',
      turma: 2023,
      dataNascimento: DateTime(2006, 8, 20),
      criadoPor: 'uid_criador_2',
    );

    setUp(() {
      pessoaRepo = FakePessoaRepository();
      pessoaFacade = PessoaFacade(
        cadastrarPessoaUseCase: CadastrarPessoaUseCase(pessoaRepo),
        atualizarPessoaUseCase: AtualizarPessoaUseCase(pessoaRepo),
        removerPessoaUseCase: RemoverPessoaUseCase(pessoaRepo),
        listarPessoasUseCase: ListarPessoasUseCase(pessoaRepo),
        buscarPessoaPorIdUseCase: BuscarPessoaPorIdUseCase(pessoaRepo),
      );
      viewModel = PessoaViewModel(pessoaFacade);
    });

    test('deve cadastrar pessoas e atualizar signal reativo', () async {
      await viewModel.cadastrarPessoaCommand(pessoa1);
      await viewModel.cadastrarPessoaCommand(pessoa2);

      expect(viewModel.pessoas.value.length, 2);
      expect(viewModel.pessoasFiltradas.value.length, 2);
    });

    test(
      'deve filtrar pessoas por curso e texto de busca de forma reativa',
      () async {
        await viewModel.cadastrarPessoaCommand(pessoa1);
        await viewModel.cadastrarPessoaCommand(pessoa2);

        // Filtro por curso
        viewModel.setFiltroCurso('INFO');
        expect(viewModel.pessoasFiltradas.value.length, 1);
        expect(viewModel.pessoasFiltradas.value.first.nome, 'Carlos Drummond');

        // Busca por texto
        viewModel.setFiltroCurso(null);
        viewModel.setBuscaTexto('Aninha');
        expect(viewModel.pessoasFiltradas.value.length, 1);
        expect(viewModel.pessoasFiltradas.value.first.nome, 'Ana Machado');

        viewModel.limparFiltros();
        expect(viewModel.pessoasFiltradas.value.length, 2);
      },
    );

    test('deve atualizar e remover pessoa com confirmação', () async {
      await viewModel.cadastrarPessoaCommand(pessoa1);
      expect(viewModel.pessoas.value.length, 1);

      // Alterar
      final alterada = pessoa1.copyWith(nome: 'Carlos Atualizado');
      await viewModel.alterarPessoaCommand(alterada);
      expect(viewModel.pessoas.value.first.nome, 'Carlos Atualizado');

      // Remover sem confirmação deve falhar
      final resFalha = await viewModel.removerPessoaCommand('p1', false);
      expect(resFalha.isFailure, isTrue);
      expect(viewModel.pessoas.value.length, 1);

      // Remover com confirmação
      final resSucesso = await viewModel.removerPessoaCommand('p1', true);
      expect(resSucesso.isSuccess, isTrue);
      expect(viewModel.pessoas.value.isEmpty, isTrue);
    });
  });

  group('AvaliacaoViewModel Tests', () {
    late FakeAvaliacaoRepository avaliacaoRepo;
    late AvaliacaoFacade avaliacaoFacade;
    late AvaliacaoViewModel viewModel;

    setUp(() {
      avaliacaoRepo = FakeAvaliacaoRepository();
      avaliacaoFacade = AvaliacaoFacade(
        salvarAvaliacaoUseCase: SalvarAvaliacaoUseCase(avaliacaoRepo),
        buscarAvaliacaoUsuarioUseCase: BuscarAvaliacaoUsuarioUseCase(
          avaliacaoRepo,
        ),
        verificarAutoavaliacaoUseCase: const VerificarAutoavaliacaoUseCase(),
      );
      viewModel = AvaliacaoViewModel(avaliacaoFacade);
    });

    test('deve inicializar com 15 critérios e pontuação padrão computada', () {
      expect(viewModel.notas.value.length, 15);
      expect(viewModel.pontuacaoTotal.value, 45); // 15 critérios x 3
      expect(viewModel.avaliacaoExistente.value, isNull);
    });

    test(
      'definirNota deve atualizar o mapa de notas e a pontuação total reativa',
      () {
        viewModel.definirNota(CriterioAvaliacao.aura, 5);
        expect(viewModel.notas.value[CriterioAvaliacao.aura.id], 5);
        expect(viewModel.pontuacaoTotal.value, 47); // 45 - 3 + 5 = 47
      },
    );

    test('salvarAvaliacaoCommand deve bloquear autoavaliação', () async {
      // Quando usuário avaliador é o mesmo que criou o perfil
      final res = await viewModel.salvarAvaliacaoCommand(
        'pessoa_1',
        'usuario_autor',
        'usuario_autor',
      );

      expect(res.isFailure, isTrue);
      expect(
        viewModel.errorMessage.value,
        contains('Não é permitido avaliar a si mesmo'),
      );
    });

    test(
      'salvarAvaliacaoCommand deve salvar com sucesso para outro usuário',
      () async {
        final res = await viewModel.salvarAvaliacaoCommand(
          'pessoa_1',
          'usuario_avaliador',
          'outro_autor',
        );

        expect(res.isSuccess, isTrue);
        expect(viewModel.avaliacaoExistente.value, isNotNull);
        expect(viewModel.errorMessage.value, isNull);

        // Carregar avaliação salva
        final carregarRes = await viewModel.carregarAvaliacaoCommand(
          'pessoa_1',
          'usuario_avaliador',
        );
        expect(carregarRes.isSuccess, isTrue);
        expect(
          viewModel.avaliacaoExistente.value?.avaliadorUid,
          'usuario_avaliador',
        );
      },
    );
  });

  group('RankingViewModel Tests', () {
    late FakePessoaRepository pessoaRepo;
    late FakeAvaliacaoRepository avaliacaoRepo;
    late RankingFacade rankingFacade;
    late RankingViewModel viewModel;

    final pessoaA = PessoaModel(
      id: 'pA',
      nome: 'Aluno A',
      apelido: 'A',
      curso: 'INFO',
      turma: 2024,
      dataNascimento: DateTime(2005, 1, 1),
      criadoPor: 'u1',
    );

    final pessoaB = PessoaModel(
      id: 'pB',
      nome: 'Aluno B',
      apelido: 'B',
      curso: 'INFO',
      turma: 2024,
      dataNascimento: DateTime(2005, 1, 1),
      criadoPor: 'u2',
    );

    setUp(() async {
      pessoaRepo = FakePessoaRepository();
      avaliacaoRepo = FakeAvaliacaoRepository();

      await pessoaRepo.cadastrarPessoa(pessoaA);
      await pessoaRepo.cadastrarPessoa(pessoaB);

      // Avaliação para pA com nota 60
      final notasA = {for (final c in CriterioAvaliacao.values) c.id: 4};
      await avaliacaoRepo.salvarAvaliacao(
        AvaliacaoModel(
          id: 'u1_pA',
          avaliadorUid: 'u1',
          pessoaId: 'pA',
          notas: notasA,
          pontuacaoTotal: 60,
          dataAvaliacao: DateTime.now(),
        ),
      );

      // Avaliação para pB com nota 75
      final notasB = {for (final c in CriterioAvaliacao.values) c.id: 5};
      await avaliacaoRepo.salvarAvaliacao(
        AvaliacaoModel(
          id: 'u1_pB',
          avaliadorUid: 'u1',
          pessoaId: 'pB',
          notas: notasB,
          pontuacaoTotal: 75,
          dataAvaliacao: DateTime.now(),
        ),
      );

      final rankingRepo = RankingRepositoryImpl(pessoaRepo, avaliacaoRepo);
      rankingFacade = RankingFacade(
        calcularRankingPessoalUseCase: CalcularRankingPessoalUseCase(
          rankingRepo,
        ),
        calcularRankingGlobalUseCase: CalcularRankingGlobalUseCase(rankingRepo),
      );

      viewModel = RankingViewModel(rankingFacade);
      viewModel.setUsuarioUid('u1');
    });

    test('carregarRankingPessoalCommand deve ordenar por nota atribuída pelo avaliador', () async {
      await viewModel.carregarRankingPessoalCommand();

      expect(viewModel.rankingPessoal.value.length, 2);
      expect(viewModel.rankingPessoal.value[0].pessoa.id, 'pB');
      expect(viewModel.rankingPessoal.value[0].pontuacao, 75);
      expect(viewModel.rankingPessoal.value[0].posicao, 1);

      expect(viewModel.rankingPessoal.value[1].pessoa.id, 'pA');
      expect(viewModel.rankingPessoal.value[1].pontuacao, 60);
      expect(viewModel.rankingPessoal.value[1].posicao, 2);
    });

    test('carregarRankingGlobalCommand deve calcular ranking geral', () async {
      await viewModel.carregarRankingGlobalCommand();

      expect(viewModel.rankingGlobal.value.length, 2);
      expect(viewModel.rankingGlobal.value[0].pessoa.id, 'pB');
      expect(viewModel.rankingGlobal.value[1].pessoa.id, 'pA');
    });
  });

  group('ThemeViewModel Tests', () {
    late FakePreferenceRepository prefRepo;
    late TemaFacade temaFacade;
    late ThemeViewModel viewModel;

    setUp(() {
      prefRepo = FakePreferenceRepository();
      temaFacade = TemaFacade(
        obterTemaSalvoUseCase: ObterTemaSalvoUseCase(prefRepo),
        salvarTemaUseCase: SalvarTemaUseCase(prefRepo),
      );
      viewModel = ThemeViewModel(temaFacade);
    });

    test('deve iniciar com tema claro e alternar com toggleTheme', () async {
      expect(viewModel.isDarkMode.value, isFalse);

      await viewModel.toggleTheme();
      expect(viewModel.isDarkMode.value, isTrue);
      expect(await prefRepo.obterTemaEscuro(), isTrue);

      await viewModel.toggleTheme();
      expect(viewModel.isDarkMode.value, isFalse);
      expect(await prefRepo.obterTemaEscuro(), isFalse);
    });

    test('carregarTema deve carregar o tema salvo previamente', () async {
      await prefRepo.salvarTemaEscuro(true);
      await viewModel.carregarTema();
      expect(viewModel.isDarkMode.value, isTrue);
    });
  });

  group('ServiceLocator Tests', () {
    test(
      'setupDependencies deve registrar e resolver todas as camadas sem erro',
      () {
        setupDependencies();

        expect(sl.isRegistered<AuthFacade>(), isTrue);
        expect(sl.isRegistered<PessoaFacade>(), isTrue);
        expect(sl.isRegistered<AvaliacaoFacade>(), isTrue);
        expect(sl.isRegistered<RankingFacade>(), isTrue);
        expect(sl.isRegistered<TemaFacade>(), isTrue);

        expect(sl.isRegistered<AuthViewModel>(), isTrue);
        expect(sl.isRegistered<PessoaViewModel>(), isTrue);
        expect(sl.isRegistered<AvaliacaoViewModel>(), isTrue);
        expect(sl.isRegistered<RankingViewModel>(), isTrue);
        expect(sl.isRegistered<ThemeViewModel>(), isTrue);
      },
    );
  });
}
