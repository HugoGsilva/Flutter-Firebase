import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/di/injection.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../pessoas/pessoas_list_view.dart';
import '../ranking/ranking_global_view.dart';
import '../ranking/ranking_pessoal_view.dart';
import '../sobre/sobre_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _localIndex = 0;

  ThemeViewModel? get _themeViewModel =>
      sl.isRegistered<ThemeViewModel>() ? sl<ThemeViewModel>() : null;
  AuthViewModel? get _authViewModel =>
      sl.isRegistered<AuthViewModel>() ? sl<AuthViewModel>() : null;
  HomeViewModel? get _homeViewModel =>
      sl.isRegistered<HomeViewModel>() ? sl<HomeViewModel>() : null;

  final List<Widget> _views = const [
    PessoasListView(),
    RankingPessoalView(),
    RankingGlobalView(),
    SobreView(),
  ];

  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do Aplicativo'),
        content: const Text('Deseja realmente encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    if (_authViewModel != null) {
      await _authViewModel!.logoutCommand();
    }
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _homeViewModel != null
        ? _homeViewModel!.currentTab.value
        : _localIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piramid Game'),
        actions: [
          if (_themeViewModel != null)
            SignalBuilder(
              builder: (context) {
                final isDark = _themeViewModel!.isDarkMode.value;
                return IconButton(
                  tooltip: isDark ? 'Ativar Tema Claro' : 'Ativar Tema Escuro',
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () => _themeViewModel!.toggleTheme(),
                );
              },
            ),
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmarLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _localIndex = index;
          });
          _homeViewModel?.setTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Pessoas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin_outlined),
            selectedIcon: Icon(Icons.person_pin_rounded),
            label: 'Ranking Pessoal',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public_rounded),
            label: 'Ranking Global',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'Sobre o App',
          ),
        ],
      ),
    );
  }
}
