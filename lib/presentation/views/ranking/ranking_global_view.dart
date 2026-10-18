import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/injection.dart';
import '../../viewmodels/ranking_viewmodel.dart';
import 'widgets/ranking_lista.dart';

class RankingGlobalView extends StatefulWidget {
  const RankingGlobalView({super.key});

  @override
  State<RankingGlobalView> createState() => _RankingGlobalViewState();
}

class _RankingGlobalViewState extends State<RankingGlobalView> {
  final _rankingViewModel = sl<RankingViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _rankingViewModel.carregarRankingGlobalCommand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final command = _rankingViewModel.carregarRankingGlobalCommand;

    return SignalBuilder(
      builder: (context) => RankingLista(
        icone: Icons.public_rounded,
        titulo: 'Ranking Global',
        pergunta: '“Na opinião dos usuários do aplicativo, quem possui o maior Nível Lenda?”',
        explicacao: 'Considera as avaliações de todos os usuários salvas no Firestore. A pontuação é a média das avaliações recebidas.',
        itens: _rankingViewModel.rankingGlobal.value,
        carregando: command.runningSignal.value,
        onRefresh: command.call,
        mensagemVazia: 'Assim que os usuários avaliarem as pessoas cadastradas, o ranking coletivo aparecerá aqui.',
        global: true,
      ),
    );
  }
}
