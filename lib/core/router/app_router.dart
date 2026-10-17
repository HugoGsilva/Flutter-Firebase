import 'package:flutter/material.dart';
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
import '../di/injection.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    if (sl.isRegistered<AuthViewModel>()) {
      sl<AuthViewModel>().addListener(notifyListeners);
    }
  }
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _RouterRefreshNotifier(),
  redirect: (BuildContext context, GoRouterState state) {
    if (!sl.isRegistered<AuthViewModel>()) {
      return null;
    }

    final authViewModel = sl<AuthViewModel>();
    final isAuthenticated = authViewModel.isAuthenticated.value;
    final location = state.matchedLocation;

    final isSplash = location == '/splash' || location == '/';
    final isAuthRoute = location == '/login' || location == '/register';

    if (isSplash) {
      return null;
    }

    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    if (isAuthenticated && isAuthRoute) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/pessoas/novo',
      builder: (context, state) => const PessoaFormScreen(),
    ),
    GoRoute(
      path: '/pessoas/editar/:id',
      builder: (context, state) {
        final pessoa = state.extra as PessoaModel?;
        return PessoaFormScreen(pessoaParaEditar: pessoa);
      },
    ),
    GoRoute(
      path: '/pessoas/detalhes/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final pessoa = state.extra as PessoaModel?;
        return PessoaDetailScreen(pessoaId: id, pessoa: pessoa);
      },
    ),
    GoRoute(
      path: '/pessoas/avaliar/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final pessoa = state.extra as PessoaModel?;
        return AvaliacaoScreen(pessoaId: id, pessoa: pessoa);
      },
    ),
  ],
);
