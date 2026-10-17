import '../../../core/result/result.dart';
import '../../models/ranking_item_model.dart';
import '../../repositories/ranking_repository.dart';

class CalcularRankingPessoalUseCase {
  const CalcularRankingPessoalUseCase(this._repository);

  final RankingRepository _repository;

  Future<Result<List<RankingItemModel>>> call(String avaliadorUid) async {
    if (avaliadorUid.trim().isEmpty) {
      return const Failure(
        FormatException('UID do avaliador não pode ser vazio.'),
      );
    }

    try {
      final ranking = await _repository.obterRankingPessoal(avaliadorUid);
      return Success(ranking);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
