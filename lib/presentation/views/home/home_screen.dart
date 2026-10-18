import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/avaliacao_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/pessoa_viewmodel.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../pessoas/pessoas_list_view.dart';
import '../ranking/ranking_global_view.dart';
import '../ranking/ranking_pessoal_view.dart';
import '../sobre/sobre_view.dart';
import '../widgets/feedback.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _themeViewModel = sl<ThemeViewModel>();
  final _authViewModel = sl<AuthViewModel>();
  final _homeViewModel = sl<HomeViewModel>();

  static const _views = [
    PessoasListView(),
    RankingPessoalView(),
    RankingGlobalView(),
    SobreView(),
  ];

  void _selecionarAba(int index) {
    _homeViewModel.setTab(index);
    switch (index) {
      case HomeViewModel.abaPessoas:
        sl<PessoaViewModel>().carregarPessoasCommand();
        sl<AvaliacaoViewModel>().carregarMinhasAvaliacoesCommand();
      case HomeViewModel.abaRankingPessoal:
        sl<RankingViewModel>().carregarRankingPessoalCommand();
      case HomeViewModel.abaRankingGlobal:
        sl<RankingViewModel>().carregarRankingGlobalCommand();
    }
  }

  Future<void> _confirmarLogout() async {
    final sair = await confirmar(
      context,
      titulo: 'Sair do aplicativo',
      mensagem: 'Deseja realmente encerrar sua sessão?',
      acao: 'Sair',
    );
    if (!sair || !mounted) return;

    await _authViewModel.logoutCommand();
    sl<PessoaViewModel>().limpar();
    sl<AvaliacaoViewModel>().limpar();
    sl<RankingViewModel>().limpar();
    _homeViewModel.setTab(HomeViewModel.abaPessoas);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final selectedIndex = _homeViewModel.currentTab.value;
        final isDark = _themeViewModel.isDarkMode.value;
        final nome = _authViewModel.currentUser.value?.nome ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('PiramidGame'),
            actions: [
              if (nome.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: Text(
                      nome.split(' ').first,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              IconButton(
                tooltip: isDark ? 'Ativar tema claro' : 'Ativar tema escuro',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                onPressed: _themeViewModel.alternarTemaCommand.call,
              ),
              IconButton(
                tooltip: 'Sair da conta',
                icon: const Icon(Icons.logout_rounded),
                onPressed: _confirmarLogout,
              ),
            ],
          ),
          body: IndexedStack(index: selectedIndex, children: _views),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: _selecionarAba,
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
                label: 'Sobre',
              ),
            ],
          ),
        );
      },
    );
  }
}
