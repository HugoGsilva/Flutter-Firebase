import '../models/ranking_item_model.dart';

abstract interface class RankingRepository {
  Future<List<RankingItemModel>> obterRankingPessoal(String avaliadorUid);
  Future<List<RankingItemModel>> obterRankingGlobal();
}
