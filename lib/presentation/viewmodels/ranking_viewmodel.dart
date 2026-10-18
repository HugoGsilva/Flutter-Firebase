import 'package:signals_flutter/signals_flutter.dart';

import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/ranking_facade.dart';
import '../../domain/models/ranking_item_model.dart';
import 'base_viewmodel.dart';

class RankingViewModel extends BaseViewModel {
  RankingViewModel(this._rankingFacade) {
    carregarRankingPessoalCommand = Command0<List<RankingItemModel>>(
      _carregarRankingPessoal,
    );
    carregarRankingGlobalCommand = Command0<List<RankingItemModel>>(
      _carregarRankingGlobal,
    );
  }

  final RankingFacade _rankingFacade;

  final rankingPessoal = signal<List<RankingItemModel>>([]);
  final rankingGlobal = signal<List<RankingItemModel>>([]);

  late final Command0<List<RankingItemModel>> carregarRankingPessoalCommand;
  late final Command0<List<RankingItemModel>> carregarRankingGlobalCommand;

  RankingItemModel? posicaoGlobalDe(String pessoaId) {
    return rankingGlobal.value
        .where((item) => item.pessoa.id == pessoaId)
        .firstOrNull;
  }

  Future<Result<List<RankingItemModel>>> _carregarRankingPessoal() {
    return executar(
      _rankingFacade.gerarRankingPessoal,
      aoConcluir: (itens) => rankingPessoal.value = itens,
    );
  }

  Future<Result<List<RankingItemModel>>> _carregarRankingGlobal() {
    return executar(
      _rankingFacade.gerarRankingGlobal,
      aoConcluir: (itens) => rankingGlobal.value = itens,
    );
  }

  void limpar() {
    rankingPessoal.value = [];
    rankingGlobal.value = [];
  }
}
