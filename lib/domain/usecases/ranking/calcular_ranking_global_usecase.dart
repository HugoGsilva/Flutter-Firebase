import '../../../core/result/result.dart';
import '../../models/ranking_item_model.dart';
import '../../repositories/ranking_repository.dart';

class CalcularRankingGlobalUseCase {
  const CalcularRankingGlobalUseCase(this._repository);

  final RankingRepository _repository;

  Future<Result<List<RankingItemModel>>> call() async {
    try {
      final ranking = await _repository.obterRankingGlobal();
      return Success(ranking);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
