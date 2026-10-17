import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/avaliacao_repository_impl.dart';
import '../../data/repositories/pessoa_repository_impl.dart';
import '../../data/repositories/preference_repository_impl.dart';
import '../../data/repositories/ranking_repository_impl.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
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
import '../../domain/repositories/ranking_repository.dart';
import '../../domain/usecases/auth/cadastrar_usuario_usecase.dart';
import '../../domain/usecases/auth/login_email_usecase.dart';
import '../../domain/usecases/auth/login_google_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/verificar_autenticado_usecase.dart';
import '../../domain/usecases/avaliacao/buscar_avaliacao_usuario_usecase.dart';
import '../../domain/usecases/avaliacao/salvar_avaliacao_usecase.dart';
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

  void registerSingleton<T extends Object>(T instance) {
    _singletons[T] = instance;
  }

  void registerLazySingleton<T extends Object>(T Function() factory) {
    _factories[T] = () {
      if (!_singletons.containsKey(T)) {
        _singletons[T] = factory();
      }
      return _singletons[T]!;
    };
  }

  void registerFactory<T extends Object>(T Function() factory) {
    _factories[T] = factory;
  }

  T get<T extends Object>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    final factory = _factories[T];
    if (factory != null) {
      return factory() as T;
    }
    throw StateError('Instância de $T não foi registrada no ServiceLocator.');
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

void setupDependencies({
  AuthService? authService,
  FirestoreService? firestoreService,
  LocalStorageService? localStorageService,
}) {
  sl.reset();

  // 1. Services
  sl.registerLazySingleton<AuthService>(() => authService ?? AuthService());
  sl.registerLazySingleton<FirestoreService>(
    () => firestoreService ?? FirestoreService(),
  );
  sl.registerLazySingleton<LocalStorageService>(
    () => localStorageService ?? LocalStorageService(),
  );

  // 2. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthService>(), sl<FirestoreService>()),
  );
  sl.registerLazySingleton<AvaliacaoRepository>(
    () => AvaliacaoRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<PessoaRepository>(
    () => PessoaRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<PreferenceRepository>(
    () => PreferenceRepositoryImpl(sl<LocalStorageService>()),
  );
  sl.registerLazySingleton<RankingRepository>(
    () => RankingRepositoryImpl(
      sl<PessoaRepository>(),
      sl<AvaliacaoRepository>(),
    ),
  );

  // 3. Use Cases
  // Auth
  sl.registerLazySingleton<CadastrarUsuarioUseCase>(
    () => CadastrarUsuarioUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoginEmailUseCase>(
    () => LoginEmailUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoginGoogleUseCase>(
    () => LoginGoogleUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<VerificarAutenticadoUseCase>(
    () => VerificarAutenticadoUseCase(sl<AuthRepository>()),
  );

  // Avaliação
  sl.registerLazySingleton<SalvarAvaliacaoUseCase>(
    () => SalvarAvaliacaoUseCase(sl<AvaliacaoRepository>()),
  );
  sl.registerLazySingleton<BuscarAvaliacaoUsuarioUseCase>(
    () => BuscarAvaliacaoUsuarioUseCase(sl<AvaliacaoRepository>()),
  );
  sl.registerLazySingleton<VerificarAutoavaliacaoUseCase>(
    () => const VerificarAutoavaliacaoUseCase(),
  );

  // Pessoa
  sl.registerLazySingleton<CadastrarPessoaUseCase>(
    () => CadastrarPessoaUseCase(sl<PessoaRepository>()),
  );
  sl.registerLazySingleton<AtualizarPessoaUseCase>(
    () => AtualizarPessoaUseCase(sl<PessoaRepository>()),
  );
  sl.registerLazySingleton<RemoverPessoaUseCase>(
    () => RemoverPessoaUseCase(sl<PessoaRepository>()),
  );
  sl.registerLazySingleton<ListarPessoasUseCase>(
    () => ListarPessoasUseCase(sl<PessoaRepository>()),
  );
  sl.registerLazySingleton<BuscarPessoaPorIdUseCase>(
    () => BuscarPessoaPorIdUseCase(sl<PessoaRepository>()),
  );

  // Ranking
  sl.registerLazySingleton<CalcularRankingPessoalUseCase>(
    () => CalcularRankingPessoalUseCase(sl<RankingRepository>()),
  );
  sl.registerLazySingleton<CalcularRankingGlobalUseCase>(
    () => CalcularRankingGlobalUseCase(sl<RankingRepository>()),
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
    ),
  );
  sl.registerLazySingleton<AvaliacaoFacade>(
    () => AvaliacaoFacade(
      salvarAvaliacaoUseCase: sl<SalvarAvaliacaoUseCase>(),
      buscarAvaliacaoUsuarioUseCase: sl<BuscarAvaliacaoUsuarioUseCase>(),
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
    () => RankingViewModel(sl<RankingFacade>(), authFacade: sl<AuthFacade>()),
  );
  sl.registerLazySingleton<ThemeViewModel>(
    () => ThemeViewModel(sl<TemaFacade>()),
  );
  sl.registerLazySingleton<HomeViewModel>(() => HomeViewModel());
}
