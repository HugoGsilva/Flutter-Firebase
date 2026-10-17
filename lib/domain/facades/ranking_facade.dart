import '../../core/result/result.dart';
import '../models/ranking_item_model.dart';
import '../usecases/ranking/calcular_ranking_global_usecase.dart';
import '../usecases/ranking/calcular_ranking_pessoal_usecase.dart';

class RankingFacade {
  const RankingFacade({
    required this.calcularRankingPessoalUseCase,
    required this.calcularRankingGlobalUseCase,
  });

  final CalcularRankingPessoalUseCase calcularRankingPessoalUseCase;
  final CalcularRankingGlobalUseCase calcularRankingGlobalUseCase;

  Future<Result<List<RankingItemModel>>> obterRankingPessoal(
    String avaliadorUid,
  ) {
    return calcularRankingPessoalUseCase(avaliadorUid);
  }

  Future<Result<List<RankingItemModel>>> obterRankingGlobal() {
    return calcularRankingGlobalUseCase();
  }
}
