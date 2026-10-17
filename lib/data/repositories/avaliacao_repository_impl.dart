import '../../domain/models/avaliacao_model.dart';
import '../../domain/repositories/avaliacao_repository.dart';
import '../services/firestore_service.dart';

class AvaliacaoRepositoryImpl implements AvaliacaoRepository {
  AvaliacaoRepositoryImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Future<void> salvarAvaliacao(AvaliacaoModel avaliacao) async {
    await _firestoreService.salvarAvaliacao(avaliacao);
  }

  @override
  Future<AvaliacaoModel?> buscarAvaliacao(
    String avaliadorUid,
    String pessoaId,
  ) async {
    return _firestoreService.obterAvaliacao(avaliadorUid, pessoaId);
  }

  @override
  Future<List<AvaliacaoModel>> listarPorPessoa(String pessoaId) async {
    return _firestoreService.listarAvaliacoesPorPessoa(pessoaId);
  }

  @override
  Future<List<AvaliacaoModel>> listarPorAvaliador(String avaliadorUid) async {
    return _firestoreService.listarAvaliacoesPorAvaliador(avaliadorUid);
  }

  @override
  Future<List<AvaliacaoModel>> listarTodas() async {
    return _firestoreService.listarTodasAvaliacoes();
  }
}
