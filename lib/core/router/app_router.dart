import 'package:go_router/go_router.dart';
import '../../presentation/views/home_view.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeView(),
    ),
  ],
);
