import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/avaliacao_repository_impl.dart';
import '../../data/repositories/pessoa_repository_impl.dart';
import '../../data/repositories/preference_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/google_auth_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../domain/facades/auth_facade.dart';
import '../../domain/facades/avaliacao_facade.dart';
import '../../domain/facades/pessoa_facade.dart';
import '../../domain/facades/ranking_facade.dart';
import '../../domain/facades/tema_facade.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../../domain/repositories/pessoa_repository.dart';
import '../../domain/repositories/preference_repository.dart';
import '../../domain/usecases/auth/cadastrar_usuario_usecase.dart';
import '../../domain/usecases/auth/login_email_usecase.dart';
import '../../domain/usecases/auth/login_google_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/verificar_autenticado_usecase.dart';
import '../../domain/usecases/auth/vincular_pessoa_usecase.dart';
import '../../domain/usecases/avaliacao/alterar_avaliacao_usecase.dart';
import '../../domain/usecases/avaliacao/consultar_avaliacao_usecase.dart';
import '../../domain/usecases/avaliacao/listar_avaliacoes_usuario_usecase.dart';
import '../../domain/usecases/avaliacao/registrar_avaliacao_usecase.dart';
import '../../domain/usecases/avaliacao/validar_avaliacao_usecase.dart';
import '../../domain/usecases/avaliacao/verificar_autoavaliacao_usecase.dart';
import '../../domain/usecases/pessoa/atualizar_pessoa_usecase.dart';
import '../../domain/usecases/pessoa/buscar_pessoa_por_id_usecase.dart';
import '../../domain/usecases/pessoa/cadastrar_pessoa_usecase.dart';
import '../../domain/usecases/pessoa/listar_pessoas_usecase.dart';
import '../../domain/usecases/pessoa/remover_pessoa_usecase.dart';
import '../../domain/usecases/ranking/calcular_ranking_global_usecase.dart';
import '../../domain/usecases/ranking/calcular_ranking_pessoal_usecase.dart';
import '../../domain/usecases/tema/obter_tema_salvo_usecase.dart';
import '../../domain/usecases/tema/salvar_tema_usecase.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/avaliacao_viewmodel.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../presentation/viewmodels/pessoa_viewmodel.dart';
import '../../presentation/viewmodels/ranking_viewmodel.dart';
import '../../presentation/viewmodels/theme_viewmodel.dart';

class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object Function()> _factories = {};
  final Map<Type, Object> _singletons = {};

  void registerLazySingleton<T extends Object>(T Function() factory) {
    _factories[T] = () => _singletons.putIfAbsent(T, factory);
  }

  T get<T extends Object>() {
    final instancia = _singletons[T] ?? _factories[T]?.call();
    if (instancia == null) {
      throw StateError('Instância de $T não foi registrada no ServiceLocator.');
    }
    return instancia as T;
  }

  T call<T extends Object>() => get<T>();

  bool isRegistered<T extends Object>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  void reset() {
    _singletons.clear();
    _factories.clear();
  }
}

final sl = ServiceLocator.instance;

/// Os parâmetros opcionais permitem substituir implementações nos testes.
void setupDependencies({
  AuthRepository? authRepository,
  PessoaRepository? pessoaRepository,
  AvaliacaoRepository? avaliacaoRepository,
  PreferenceRepository? preferenceRepository,
}) {
  sl.reset();

  // 1. Services
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
  sl.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  // 2. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () =>
        authRepository ??
        AuthRepositoryImpl(
          sl<AuthService>(),
          sl<GoogleAuthService>(),
          sl<FirestoreService>(),
        ),
  );
  sl.registerLazySingleton<PessoaRepository>(
    () => pessoaRepository ?? PessoaRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<AvaliacaoRepository>(
    () =>
        avaliacaoRepository ?? AvaliacaoRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<PreferenceRepository>(
    () =>
        preferenceRepository ??
        PreferenceRepositoryImpl(sl<LocalStorageService>()),
  );

  // 3. Use Cases
  // Auth
  sl.registerLazySingleton<CadastrarUsuarioUseCase>(
    () => CadastrarUsuarioUseCase(
      sl<AuthRepository>(),
      sl<PreferenceRepository>(),
    ),
  );
  sl.registerLazySingleton<LoginEmailUseCase>(
    () => LoginEmailUseCase(sl<AuthRepository>(), sl<PreferenceRepository>()),
  );
  sl.registerLazySingleton<LoginGoogleUseCase>(
    () => LoginGoogleUseCase(sl<AuthRepository>(), sl<PreferenceRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>(), sl<PreferenceRepository>()),
  );
  sl.registerLazySingleton<VerificarAutenticadoUseCase>(
    () => VerificarAutenticadoUseCase(
      sl<AuthRepository>(),
      sl<PreferenceRepository>(),
    ),
  );
  sl.registerLazySingleton<VincularPessoaUseCase>(
    () => VincularPessoaUseCase(
      sl<AuthRepository>(),
      sl<PessoaRepository>(),
      sl<PreferenceRepository>(),
    ),
  );

  // Avaliação
  sl.registerLazySingleton<VerificarAutoavaliacaoUseCase>(
    () => VerificarAutoavaliacaoUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ValidarAvaliacaoUseCase>(
    () => ValidarAvaliacaoUseCase(
      sl<AuthRepository>(),
      sl<PessoaRepository>(),
      sl<VerificarAutoavaliacaoUseCase>(),
    ),
  );
  sl.registerLazySingleton<RegistrarAvaliacaoUseCase>(
    () => RegistrarAvaliacaoUseCase(
      sl<AvaliacaoRepository>(),
      sl<ValidarAvaliacaoUseCase>(),
    ),
  );
  sl.registerLazySingleton<AlterarAvaliacaoUseCase>(
    () => AlterarAvaliacaoUseCase(
      sl<AvaliacaoRepository>(),
      sl<ValidarAvaliacaoUseCase>(),
    ),
  );
  sl.registerLazySingleton<ConsultarAvaliacaoUseCase>(
    () => ConsultarAvaliacaoUseCase(
      sl<AvaliacaoRepository>(),
      sl<AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<ListarAvaliacoesUsuarioUseCase>(
    () => ListarAvaliacoesUsuarioUseCase(
      sl<AvaliacaoRepository>(),
      sl<AuthRepository>(),
    ),
  );

  // Pessoa
  sl.registerLazySingleton<CadastrarPessoaUseCase>(
    () => CadastrarPessoaUseCase(sl<PessoaRepository>(), sl<AuthRepository>()),
  );
  sl.registerLazySingleton<AtualizarPessoaUseCase>(
    () => AtualizarPessoaUseCase(sl<PessoaRepository>()),
  );
  sl.registerLazySingleton<RemoverPessoaUseCase>(
    () => RemoverPessoaUseCase(sl<PessoaRepository>(), sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ListarPessoasUseCase>(
    () => ListarPessoasUseCase(sl<PessoaRepository>()),
  );
  sl.registerLazySingleton<BuscarPessoaPorIdUseCase>(
    () => BuscarPessoaPorIdUseCase(sl<PessoaRepository>()),
  );

  // Ranking
  sl.registerLazySingleton<CalcularRankingPessoalUseCase>(
    () => CalcularRankingPessoalUseCase(
      sl<PessoaRepository>(),
      sl<AvaliacaoRepository>(),
      sl<AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<CalcularRankingGlobalUseCase>(
    () => CalcularRankingGlobalUseCase(
      sl<PessoaRepository>(),
      sl<AvaliacaoRepository>(),
    ),
  );

  // Tema
  sl.registerLazySingleton<ObterTemaSalvoUseCase>(
    () => ObterTemaSalvoUseCase(sl<PreferenceRepository>()),
  );
  sl.registerLazySingleton<SalvarTemaUseCase>(
    () => SalvarTemaUseCase(sl<PreferenceRepository>()),
  );

  // 4. Facades
  sl.registerLazySingleton<AuthFacade>(
    () => AuthFacade(
      cadastrarUsuarioUseCase: sl<CadastrarUsuarioUseCase>(),
      loginEmailUseCase: sl<LoginEmailUseCase>(),
      loginGoogleUseCase: sl<LoginGoogleUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      verificarAutenticadoUseCase: sl<VerificarAutenticadoUseCase>(),
      vincularPessoaUseCase: sl<VincularPessoaUseCase>(),
    ),
  );
  sl.registerLazySingleton<AvaliacaoFacade>(
    () => AvaliacaoFacade(
      registrarAvaliacaoUseCase: sl<RegistrarAvaliacaoUseCase>(),
      alterarAvaliacaoUseCase: sl<AlterarAvaliacaoUseCase>(),
      consultarAvaliacaoUseCase: sl<ConsultarAvaliacaoUseCase>(),
      listarAvaliacoesUsuarioUseCase: sl<ListarAvaliacoesUsuarioUseCase>(),
      verificarAutoavaliacaoUseCase: sl<VerificarAutoavaliacaoUseCase>(),
    ),
  );
  sl.registerLazySingleton<PessoaFacade>(
    () => PessoaFacade(
      cadastrarPessoaUseCase: sl<CadastrarPessoaUseCase>(),
      atualizarPessoaUseCase: sl<AtualizarPessoaUseCase>(),
      removerPessoaUseCase: sl<RemoverPessoaUseCase>(),
      listarPessoasUseCase: sl<ListarPessoasUseCase>(),
      buscarPessoaPorIdUseCase: sl<BuscarPessoaPorIdUseCase>(),
    ),
  );
  sl.registerLazySingleton<RankingFacade>(
    () => RankingFacade(
      calcularRankingPessoalUseCase: sl<CalcularRankingPessoalUseCase>(),
      calcularRankingGlobalUseCase: sl<CalcularRankingGlobalUseCase>(),
    ),
  );
  sl.registerLazySingleton<TemaFacade>(
    () => TemaFacade(
      obterTemaSalvoUseCase: sl<ObterTemaSalvoUseCase>(),
      salvarTemaUseCase: sl<SalvarTemaUseCase>(),
    ),
  );

  // 5. ViewModels
  sl.registerLazySingleton<AuthViewModel>(
    () => AuthViewModel(sl<AuthFacade>()),
  );
  sl.registerLazySingleton<PessoaViewModel>(
    () => PessoaViewModel(sl<PessoaFacade>()),
  );
  sl.registerLazySingleton<AvaliacaoViewModel>(
    () => AvaliacaoViewModel(sl<AvaliacaoFacade>()),
  );
  sl.registerLazySingleton<RankingViewModel>(
    () => RankingViewModel(sl<RankingFacade>()),
  );
  sl.registerLazySingleton<ThemeViewModel>(
    () => ThemeViewModel(sl<TemaFacade>()),
  );
  sl.registerLazySingleton<HomeViewModel>(() => HomeViewModel());
}
