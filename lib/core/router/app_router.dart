import 'package:go_router/go_router.dart';

import '../../domain/models/pessoa_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/auth/register_screen.dart';
import '../../presentation/views/avaliacao/avaliacao_screen.dart';
import '../../presentation/views/home/home_screen.dart';
import '../../presentation/views/pessoas/pessoa_detail_screen.dart';
import '../../presentation/views/pessoas/pessoa_form_screen.dart';
import '../../presentation/views/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const cadastro = '/register';
  static const home = '/home';
  static const novaPessoa = '/pessoas/novo';

  static String detalhes(String id) => '/pessoas/detalhes/$id';
  static String editar(String id) => '/pessoas/editar/$id';
  static String avaliar(String id) => '/pessoas/avaliar/$id';
}

/// Somente usuários autenticados acessam as rotas principais. A splash fica
/// livre porque é nela que a sessão é verificada.
GoRouter criarRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authViewModel.isAuthenticated,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == AppRoutes.splash) return null;

      final autenticado = authViewModel.isAuthenticated.value;
      final rotaPublica =
          location == AppRoutes.login || location == AppRoutes.cadastro;

      if (!autenticado && !rotaPublica) return AppRoutes.login;
      if (autenticado && rotaPublica) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoutes.splash),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.cadastro,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.novaPessoa,
        builder: (_, _) => const PessoaFormScreen(),
      ),
      GoRoute(
        path: '/pessoas/editar/:id',
        builder: (_, state) => PessoaFormScreen(
          pessoaId: state.pathParameters['id'],
          pessoaParaEditar: state.extra as PessoaModel?,
        ),
      ),
      GoRoute(
        path: '/pessoas/detalhes/:id',
        builder: (_, state) => PessoaDetailScreen(
          pessoaId: state.pathParameters['id'] ?? '',
          pessoa: state.extra as PessoaModel?,
        ),
      ),
      GoRoute(
        path: '/pessoas/avaliar/:id',
        builder: (_, state) => AvaliacaoScreen(
          pessoaId: state.pathParameters['id'] ?? '',
          pessoa: state.extra as PessoaModel?,
        ),
      ),
    ],
  );
}
