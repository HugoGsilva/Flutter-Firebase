import '../models/avaliacao_model.dart';

abstract interface class AvaliacaoRepository {
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao);
  Future<AvaliacaoModel?> buscarAvaliacao(String avaliadorUid, String pessoaId);
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId);
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid);
  Future<List<AvaliacaoModel>> listarTodas();
}
