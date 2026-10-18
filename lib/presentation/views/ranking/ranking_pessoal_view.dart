import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import 'widgets/ranking_lista.dart';

class RankingPessoalView extends StatefulWidget {
  const RankingPessoalView({super.key});

  @override
  State<RankingPessoalView> createState() => _RankingPessoalViewState();
}

class _RankingPessoalViewState extends State<RankingPessoalView> {
  final _rankingViewModel = sl<RankingViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _rankingViewModel.carregarRankingPessoalCommand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final command = _rankingViewModel.carregarRankingPessoalCommand;

    return SignalBuilder(
      builder: (context) => RankingLista(
        icone: Icons.person_pin_rounded,
        titulo: 'Ranking Pessoal',
        pergunta: '“Na minha opinião, quem possui o maior Nível Lenda?”',
        explicacao: 'Considera exclusivamente as avaliações feitas por você. As avaliações dos demais usuários não interferem aqui.',
        itens: _rankingViewModel.rankingPessoal.value,
        carregando: command.runningSignal.value,
        onRefresh: command.call,
        mensagemVazia: 'Avalie pessoas na aba "Pessoas" para montar o seu ranking pessoal.',
      ),
    );
  }
}
